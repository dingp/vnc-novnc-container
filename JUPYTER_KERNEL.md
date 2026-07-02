# VNC/noVNC Jupyter Kernel

This repository includes a Jupyter kernelspec for running the Debian VNC/noVNC image as a Python kernel with `podman-hpc`.

The kernelspec follows the NERSC `podman-hpc` container-kernel pattern: the host launches `podman-hpc run --rm --jupyter ...`, and the container starts `python3 -m ipykernel_launcher -f {connection_file}`. The `--jupyter` flag handles the Jupyter connection path and the basic `$HOME` and `/tmp` mounts.

## Bootstrap the Kernel

From the repository root:

```sh
scripts/install-jupyter-kernel.sh
```

The bootstrap script installs the Python package in editable mode for the current user and copies the sample kernelspec into:

```text
${HOME}/.local/share/jupyter/kernels/vnc-novnc
```

Useful options:

- `--force`: replace an existing `vnc-novnc` kernelspec.
- `--source-wrapper`: make the installed kernel wrapper import `vnc_novnc` directly from this checkout.
- `--no-pip-install`: copy the kernelspec without running `pip install`.
- `--prefix DIR`: install under `DIR/share/jupyter/kernels`.
- `--name NAME`: use a different kernelspec directory name.
- `--display-name NAME`: use a different display name in Jupyter.

For development from a checkout:

```sh
scripts/install-jupyter-kernel.sh --source-wrapper --force
```

## Manual Package Install

The package can also be installed directly:

```sh
python3 -m pip install --user -e .
```

This installs these commands:

```sh
run-vnc-novnc
vnc-novnc-kernel-wrapper
```

Restart or refresh JupyterLab if the new kernel does not appear immediately after running the bootstrap script.

## What the Wrapper Does

When Jupyter starts the kernel, `kernel-wrapper` runs:

```sh
python3 -m vnc_novnc.kernel --config "{resource_dir}/vnc-novnc.yaml" -f "{connection_file}"
```

The Python wrapper:

- Chooses an available host port for noVNC unless `host_novnc_port` is set.
- Generates a one-time VNC password.
- Writes the password to a temporary `0600` file on the host.
- Mounts that file read-only at `/run/secrets/vnc-password` inside the container.
- Publishes noVNC on the selected host port.
- Names the container and explicitly stops/removes it if the host wrapper receives
  `INT`, `TERM`, or `HUP`, which covers console-style shutdowns that may
  terminate the wrapper before the in-container kernel exits cleanly.
- Uses `podman-hpc run --rm --jupyter`.
- Passes `--userns=keep-id` and `--group-add=keep-groups` from the YAML config.
- Adds a `--passwd-entry` for the host UID when `keep-id` is active so the
  notebook user resolves to `/bin/bash` inside the container.
- Mounts `$SCRATCH` and `$CFS` from the YAML config.
- Passes non-secret noVNC connection metadata into the container.

Inside the container, `vnc-novnc-jupyter-kernel` starts VNC/noVNC in the background and then starts `ipykernel`.
The image declares only the noVNC port as exposed metadata; raw VNC remains
internal unless a runner explicitly publishes it.

## Notebook Usage

After selecting the `Debian VNC/noVNC (podman-hpc)` kernel, the noVNC URL and one-time password are displayed automatically in the output area of the first notebook cell you run.

You can also show the connection details manually at any time:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

This displays the proxied noVNC URL and reads the one-time VNC password from `/run/secrets/vnc-password`.

## Kernel Configuration

The sample kernel config is `kernels/vnc-novnc/vnc-novnc.yaml`:

```yaml
image: ghcr.io/dingp/vnc-novnc-container:debian-12-main
userns: keep-id
keep_groups: true
pull_policy: newer

volume:
  - "${SCRATCH}:${SCRATCH}:rw"
  - "${CFS}:${CFS}:rw"
```

The wrapper also passes selected host environment variables into the container, including `USER`, `HOME`, `SCRATCH`, `CFS`, `JUPYTERHUB_SERVICE_PREFIX`, and `JUPYTER_PROXY_*`.

`$HOME` and `/tmp` are not listed in the kernel YAML because `podman-hpc --jupyter` handles those mounts.

The default `pull_policy: newer` makes the kernel wrapper pass `--pull=newer` to `podman-hpc run`. `newer` checks the registry and pulls only when the remote tag is newer than the local image. `always` pulls on every kernel start, which guarantees a registry check and fresh download attempt each time, but can slow startup and fail if the registry is temporarily unavailable.
