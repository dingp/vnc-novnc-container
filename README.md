# VNC/noVNC Desktop Container for NERSC

This repository builds a Debian 12 desktop container with:

- TigerVNC and noVNC
- Chromium browser
- `sshproxy`
- fvwm3 desktop
- GUI terminal, `tmux`, and `vim`
- Python `ipykernel` support for use as a Jupyter kernel

The default image name used by the helper scripts is:

```text
ghcr.io/dingp/vnc-novnc-container:debian-12-main
```

## Build

At NERSC, build with `podman-hpc`:

```sh
podman-hpc build -f Dockerfile -t ghcr.io/dingp/vnc-novnc-container:debian-12-main .
```

## Run the Desktop

Use the Python helper with the NERSC-oriented config:

```sh
scripts/run-vnc-novnc.py --config scripts/run-vnc-novnc.yaml
```

The helper generates a one-time VNC password, chooses a noVNC host port, does not expose the raw VNC port by default, and prints a Jupyter Server Proxy URL when it can determine the Jupyter user/server prefix.

## Jupyter Kernel

Install the Python package locally:

```sh
scripts/install-jupyter-kernel.sh
```

For development from a checkout without relying on the editable pip install, use:

```sh
scripts/install-jupyter-kernel.sh --source-wrapper --force
```

Then select `Debian VNC/noVNC (podman-hpc)` in JupyterLab and run:

```python
1 + 1
```

The noVNC URL and one-time password are displayed automatically in the first cell output. To show them again manually:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

See [RUN_VNC_NOVNC.md](RUN_VNC_NOVNC.md) and [JUPYTER_KERNEL.md](JUPYTER_KERNEL.md) for details.
