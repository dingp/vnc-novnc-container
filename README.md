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
ghcr.io/dingp/debian:12-vnc-novnc
```

## Build

At NERSC, build with `podman-hpc`:

```sh
podman-hpc build -f Dockerfile -t ghcr.io/dingp/debian:12-vnc-novnc .
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
python3 -m pip install --user -e .
```

Install the sample kernelspec:

```sh
mkdir -p "${HOME}/.local/share/jupyter/kernels/vnc-novnc"
cp kernels/vnc-novnc/kernel.json "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
cp kernels/vnc-novnc/kernel-wrapper "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
cp kernels/vnc-novnc/vnc-novnc.yaml "${HOME}/.local/share/jupyter/kernels/vnc-novnc/"
```

Then select `Debian VNC/noVNC (podman-hpc)` in JupyterLab and run:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

See [RUN_VNC_NOVNC.md](RUN_VNC_NOVNC.md) and [JUPYTER_KERNEL.md](JUPYTER_KERNEL.md) for details.
