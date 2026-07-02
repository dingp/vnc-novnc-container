# VNC/noVNC Desktop Container for NERSC

This repository builds VNC/noVNC desktop containers for NERSC.

The default Debian 12 image includes:

- TigerVNC and noVNC
- Chromium browser
- `sshproxy`
- fvwm3 desktop
- GUI terminal, `tmux`, and `vim`
- Python `ipykernel` support for use as a Jupyter kernel

There is also an openSUSE Leap 15.6 variant with XFCE instead of fvwm3.

The default image name used by the helper scripts is the Debian build:

```text
ghcr.io/dingp/vnc-novnc-container:debian-12-main
```

The openSUSE image is published as:

```text
ghcr.io/dingp/vnc-novnc-container:opensuse-15.6-main
```

## Build

At NERSC, build with `podman-hpc`:

```sh
podman-hpc build -f images/debian-12/fvwm3/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:debian-12-main .
```

Build the openSUSE Leap 15.6 XFCE image with:

```sh
podman-hpc build -f images/opensuse-15.6/xfce/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:opensuse-15.6-main .
```

## Repository Layout

- `images/<base-os>/<desktop>/Dockerfile`: image variants.
- `container/`: scripts and desktop config shared by image variants.
- `vnc_novnc/`: host and in-container Python helpers.
- `kernels/`: sample Jupyter kernelspec.
- `scripts/`: install and run helpers.

## Run the Desktop

Use the Python helper with the NERSC-oriented config:

```sh
scripts/run-vnc-novnc.py --config scripts/run-vnc-novnc.yaml
```

The helper generates a one-time VNC password, chooses a noVNC host port, does not expose the raw VNC port by default, and prints a Jupyter Server Proxy URL when it can determine the Jupyter user/server prefix.

The sample configs use `pull_policy: newer`, so `podman-hpc run` checks for a newer image tag before starting without forcing a full pull every time.

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
