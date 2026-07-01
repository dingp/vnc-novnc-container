# VNC/noVNC Jupyter Kernel

This repository includes a Jupyter kernelspec for running the Debian VNC/noVNC image as a Python kernel with `podman-hpc`.

The kernelspec follows the NERSC `podman-hpc` container-kernel pattern: the host launches `podman-hpc run --rm --jupyter ...`, and the container starts `python3 -m ipykernel_launcher -f {connection_file}`. The `--jupyter` flag handles the Jupyter connection path and the basic `$HOME` and `/tmp` mounts.

## Install the Package

From the repository root:

```sh
python3 -m pip install --user -e .
```

This installs these commands:

```sh
run-vnc-novnc
vnc-novnc-kernel-wrapper
```

The package can also be imported from notebooks:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

## Install the Kernelspec

Install the sample kernelspec into your Jupyter kernels directory:

```sh
mkdir -p "${HOME}/.local/share/jupyter/kernels/vnc-novnc"
cp kernels/vnc-novnc/kernel.json "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
cp kernels/vnc-novnc/kernel-wrapper "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
cp kernels/vnc-novnc/vnc-novnc.yaml "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
```

Validate the kernelspec JSON:

```sh
jq . "${HOME}/.local/share/jupyter/kernels/vnc-novnc/kernel.json"
```

Restart or refresh JupyterLab if the new kernel does not appear immediately.

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
- Uses `podman-hpc run --rm --jupyter`.
- Passes `--userns=keep-id` and `--group-add=keep-groups` from the YAML config.
- Mounts `$SCRATCH` and `$CFS` from the YAML config.
- Passes non-secret noVNC connection metadata into the container.

Inside the container, `vnc-novnc-jupyter-kernel` starts VNC/noVNC in the background and then starts `ipykernel`.

## Notebook Usage

After selecting the `Debian VNC/noVNC (podman-hpc)` kernel, run:

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

volume:
  - "${SCRATCH}:${SCRATCH}:rw"
  - "${CFS}:${CFS}:rw"
```

The wrapper also passes selected host environment variables into the container, including `USER`, `HOME`, `SCRATCH`, `CFS`, `JUPYTERHUB_SERVICE_PREFIX`, and `JUPYTER_PROXY_*`.

`$HOME` and `/tmp` are not listed in the kernel YAML because `podman-hpc --jupyter` handles those mounts.
