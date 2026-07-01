# Using the VNC/noVNC Helpers

`scripts/run-vnc-novnc.sh` and `scripts/run-vnc-novnc.py` start the Debian 12 VNC/noVNC desktop image with safer defaults for interactive use on NERSC systems, especially from Jupyter. The Python helper has the same default behavior as the shell helper and adds command-line options for bind mounts, environment passthrough, user namespace settings, and extra `podman-hpc` arguments.

## What It Does

The helper script:

- Starts `ghcr.io/dingp/vnc-novnc-container:debian-12-main` with `podman-hpc`.
- Generates a one-time VNC password at runtime.
- Stores the password in a temporary `0600` file and mounts that file read-only into the container.
- Avoids putting the VNC password in shell history or in the `podman-hpc run` command line.
- Chooses a random host port for noVNC when `HOST_NOVNC_PORT` is not set.
- Publishes only the noVNC port by default.
- Does not expose the raw VNC server port unless `EXPOSE_VNC=1` is set.
- Prints the noVNC access URL and one-time VNC password before starting the container.
- Prints a Jupyter Server Proxy URL when it can determine the Jupyter user/server path.

Inside the container, the VNC server listens on `VNC_PORT` and noVNC listens on `NOVNC_PORT`. On the host, only noVNC is exposed by default.

## Basic Usage

From the repository root:

```sh
scripts/run-vnc-novnc.py
```

To use the default NERSC-oriented YAML config:

```sh
scripts/run-vnc-novnc.py --config scripts/run-vnc-novnc.yaml
```

The runner is also available as a Python module after installing the package:

```sh
python3 -m pip install --user -e .
python3 -m vnc_novnc --config scripts/run-vnc-novnc.yaml
```

The script prints output like:

```text
Image: ghcr.io/dingp/vnc-novnc-container:debian-12-main
noVNC: https://jupyter.nersc.gov/user/your-user-name/perlmutter-login-node/proxy/49967/vnc.html?port=443&host=jupyter.nersc.gov&path=user%2Fyour-user-name%2Fperlmutter-login-node%2Fproxy%2F49967
One-time VNC password: AbC123xY
VNC server port is not exposed on the host.
```

Open the printed `noVNC` URL in a browser and enter the printed one-time VNC password.

## Jupyter Server Proxy URLs

When run inside a Jupyter session, the script uses `JUPYTERHUB_SERVICE_PREFIX` to build the proxied noVNC URL. This is the preferred path because JupyterHub already provides the username and server name.

For example, if the service prefix is:

```text
/user/your-user-name/muller-login-node-base/
```

and the selected noVNC host port is `49967`, the printed URL is:

```text
https://jupyter.nersc.gov/user/your-user-name/muller-login-node-base/proxy/49967/vnc.html?port=443&host=jupyter.nersc.gov&path=user%2Fyour-user-name%2Fmuller-login-node-base%2Fproxy%2F49967
```

If the helper is not running inside Jupyter, provide the server path explicitly:

```sh
scripts/run-vnc-novnc.py --jupyter-proxy-server perlmutter-login-node
```

The server name is the Jupyter server type, such as `muller-login-node-base` or `perlmutter-login-node`.

## Configuration

The Python helper can read defaults from a YAML config file:

```sh
scripts/run-vnc-novnc.py --config scripts/run-vnc-novnc.yaml
```

The included `scripts/run-vnc-novnc.yaml` uses `--userns=keep-id`, `--group-add=keep-groups`, and bind mounts `$HOME`, `$SCRATCH`, and `$CFS` into the same paths inside the container. Environment variables in YAML strings are expanded on the host when the script starts.

YAML keys use the long option names with underscores instead of dashes. For example:

```yaml
userns: keep-id
keep_groups: true
pull_policy: newer

volume:
  - "${HOME}:${HOME}:rw"
  - "${SCRATCH}:${SCRATCH}:rw"
  - "${CFS}:${CFS}:rw"
```

Precedence is: built-in defaults, YAML config, environment variables, then command-line arguments. Repeated list options such as `volume`, `mount`, `env`, `group_add`, and `extra_podman_args` are initialized from YAML, and additional command-line occurrences are appended.

Common settings:

| Variable | Default | Purpose |
| --- | --- | --- |
| `IMAGE` | `ghcr.io/dingp/vnc-novnc-container:debian-12-main` | Container image to run. |
| `HOST_NOVNC_ADDR` | `127.0.0.1` | Host address used for the noVNC port publication. |
| `HOST_NOVNC_PORT` | random | Host port for noVNC. |
| `NOVNC_PORT` | `6080` | noVNC port inside the container. |
| `VNC_PORT` | `5901` | VNC server port inside the container. |
| `EXPOSE_VNC` | `0` | Set to `1` to also publish the raw VNC server port. |
| `VNC_PASSWORD_LENGTH` | `8` | Length of the generated one-time VNC password. |

Python helper container options:

| Option | Purpose |
| --- | --- |
| `-v`, `--volume HOST:CONTAINER[:OPTIONS]` | Add a bind mount or volume spec. May be repeated. |
| `--mount SPEC` | Add a Podman `--mount` spec. May be repeated. |
| `-e`, `--env NAME[=VALUE]` | Pass an environment variable into the container. May be repeated. |
| `--config FILE` | Read default values from a YAML config file. |
| `--pull-policy POLICY` | Pass `--pull=POLICY` to `podman-hpc run`. Choices are `newer`, `always`, `missing`, and `never`; default is `newer`. |
| `--userns=keep-id` | Pass `--userns=keep-id` to `podman-hpc`. |
| `--userns-keep-id` | Shorthand for `--userns=keep-id`. |
| `--group-add=keep-groups` | Pass `--group-add=keep-groups` to `podman-hpc`. |
| `--keep-groups` | Shorthand for `--group-add=keep-groups`. |
| `--dry-run` | Print the generated command without running the container. |
| `--` | Pass following arguments directly to `podman-hpc run` before the image name. |

Pull policy:

- `newer` checks the registry and pulls the image only when the remote tag is newer than the local copy. This keeps the image fresh while avoiding unnecessary downloads.
- `always` pulls the image every time before running. This is the strongest freshness policy, but it makes startup slower and depends on registry availability for every launch.
- `missing` pulls only when the image is not already present locally.
- `never` never pulls and requires the image to already exist locally.

Jupyter URL settings:

| Variable | Default | Purpose |
| --- | --- | --- |
| `JUPYTER_PROXY_BASE_URL` | `https://jupyter.nersc.gov` | Public Jupyter base URL. |
| `JUPYTER_PROXY_HOST` | `jupyter.nersc.gov` | Host query parameter passed to noVNC. |
| `JUPYTER_PROXY_HTTPS_PORT` | `443` | Port query parameter passed to noVNC. |
| `JUPYTER_PROXY_PREFIX` | `JUPYTERHUB_SERVICE_PREFIX` | Full Jupyter user/server prefix. |
| `JUPYTER_PROXY_USER` | `USER` | Username used when `JUPYTER_PROXY_PREFIX` is absent. |
| `JUPYTER_PROXY_SERVER` | unset | Jupyter server name used when `JUPYTER_PROXY_PREFIX` is absent. |

Raw VNC exposure settings:

| Variable | Default | Purpose |
| --- | --- | --- |
| `VNC_HOST_ADDR` | `127.0.0.1` | Host address for raw VNC publication when `EXPOSE_VNC=1`. |
| `VNC_HOST_PORT` | `VNC_PORT` | Host port for raw VNC publication when `EXPOSE_VNC=1`. |

## Examples

Use a fixed noVNC host port:

```sh
scripts/run-vnc-novnc.py --host-novnc-port 49967
```

Use a locally built image:

```sh
scripts/run-vnc-novnc.py --image localhost/debugging-container-vnc-novnc:latest
```

Run outside Jupyter but still print a Jupyter proxy URL:

```sh
scripts/run-vnc-novnc.py --jupyter-proxy-server muller-login-node-base
```

Expose the raw VNC server port in addition to noVNC:

```sh
scripts/run-vnc-novnc.py --expose-vnc
```

Use a custom raw VNC host port:

```sh
scripts/run-vnc-novnc.py --expose-vnc --vnc-host-port 5905
```

Mount host directories into the container:

```sh
scripts/run-vnc-novnc.py \
  -v "${HOME}:${HOME}:rw" \
  -v "${SCRATCH}:${SCRATCH}:rw"
```

Use the included YAML config for common NERSC mounts and identity handling:

```sh
scripts/run-vnc-novnc.py --config scripts/run-vnc-novnc.yaml
```

Run with host identity/group handling:

```sh
scripts/run-vnc-novnc.py --userns=keep-id --group-add=keep-groups
```

The shorthand form is equivalent:

```sh
scripts/run-vnc-novnc.py --userns-keep-id --keep-groups
```

Pass environment variables into the container:

```sh
scripts/run-vnc-novnc.py -e NERSC_HOST -e MY_SETTING=value
```

Pass extra `podman-hpc run` arguments:

```sh
scripts/run-vnc-novnc.py -- --ipc=host
```

Use the image as a Jupyter kernel:

```sh
python3 -m pip install --user -e .
mkdir -p "${HOME}/.local/share/jupyter/kernels/vnc-novnc"
cp kernels/vnc-novnc/kernel.json "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
cp kernels/vnc-novnc/kernel-wrapper "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
cp kernels/vnc-novnc/vnc-novnc.yaml "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
```

Then select `Debian VNC/noVNC (podman-hpc)` in Jupyter and run:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

See [JUPYTER_KERNEL.md](JUPYTER_KERNEL.md) for details.

## Security Notes

The helper avoids passing the VNC password as an environment variable or command-line argument. It writes the generated password to a temporary file, mounts that file read-only into the container, and deletes the temporary directory when the helper exits.

By default, raw VNC is not exposed on the host. Prefer the printed noVNC URL unless a separate VNC client is required.
