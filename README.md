# VNC/noVNC Desktop Container for NERSC

This repository builds VNC/noVNC desktop containers for NERSC.

The default Debian 12 image includes:

- TigerVNC and noVNC
- Chromium browser
- `sshproxy`
- fvwm3 desktop
- GUI terminal, `tmux`, and `vim`
- Python `ipykernel` support for use as a Jupyter kernel

Additional variants cover Debian, Ubuntu, AlmaLinux, and openSUSE bases with
fvwm3 or XFCE desktops where those packages are available.

The default image name used by the helper scripts is the Debian fvwm3 build:

```text
ghcr.io/dingp/vnc-novnc-container:debian-12-main
```

Published branch tags include:

```text
ghcr.io/dingp/vnc-novnc-container:debian-12-main
ghcr.io/dingp/vnc-novnc-container:debian-12-xfce-main
ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-fvwm3-main
ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-xfce-main
ghcr.io/dingp/vnc-novnc-container:alma-9-fvwm3-main
ghcr.io/dingp/vnc-novnc-container:alma-9-xfce-main
ghcr.io/dingp/vnc-novnc-container:opensuse-15.6-main
```

## Build

At NERSC, build with `podman-hpc`:

```sh
podman-hpc build -f images/debian-12/fvwm3/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:debian-12-main .
```

Build another variant by selecting its Dockerfile:

```sh
podman-hpc build -f images/debian-12/xfce/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:debian-12-xfce-main .
podman-hpc build -f images/ubuntu-24.04/fvwm3/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-fvwm3-main .
podman-hpc build -f images/ubuntu-24.04/xfce/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-xfce-main .
podman-hpc build -f images/alma-9/fvwm3/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:alma-9-fvwm3-main .
podman-hpc build -f images/alma-9/xfce/Dockerfile -t ghcr.io/dingp/vnc-novnc-container:alma-9-xfce-main .
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

The sample configs use `pull_policy: missing`, so kernel startup does not spend time checking for a newer image when the image is already present on the node.

## Jupyter Kernel

Install the Python package locally:

```sh
scripts/install-jupyter-kernel.sh
```

This installs the default Debian 12 fvwm3 kernelspec as
`vnc-novnc-debian12-fvwm3` with display name `VNC-debian12-fvwm3`.
Select another variant by passing `DISTRO DESKTOP`:

```sh
scripts/install-jupyter-kernel.sh ubuntu24.04 xfce --force
scripts/install-jupyter-kernel.sh opensuse15.6 xfce --force
```

Install all supported distro/desktop kernelspecs:

```sh
scripts/install-jupyter-kernel.sh --all --force
```

Pre-pull the image for the kernelspec while installing it:

```sh
scripts/install-jupyter-kernel.sh ubuntu24.04 xfce --prepull --force
scripts/install-jupyter-kernel.sh --all --prepull --force
```

Pre-pulling is useful on nodes that do not already have the image in local `podman-hpc` storage; otherwise Jupyter may time out while the kernel process is still pulling and preparing the image.

For development from a checkout without relying on the editable pip install, use:

```sh
scripts/install-jupyter-kernel.sh --source-wrapper --force
```

Then select a `VNC-DISTRO-DESKTOP` kernel in JupyterLab and run:

```python
1 + 1
```

The noVNC URL and one-time password are displayed automatically in the first cell output. To show them again manually:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

See [RUN_VNC_NOVNC.md](RUN_VNC_NOVNC.md) and [JUPYTER_KERNEL.md](JUPYTER_KERNEL.md) for details.
