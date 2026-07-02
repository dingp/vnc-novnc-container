# VNC/noVNC Desktop Container for NERSC

This repository builds VNC/noVNC desktop containers for NERSC and provides
helpers for running them directly or as Jupyter kernels with `podman-hpc`.

The default image is Debian 12 with fvwm3:

```text
ghcr.io/dingp/vnc-novnc-container:debian-12-main
```

Images include TigerVNC, noVNC, Chromium, `sshproxy`, a desktop environment,
terminal tools, common debugging/networking tools, and Python `ipykernel`
support. The VNC/noVNC helper code is installed in the container under
`/usr/local/lib/vnc-novnc`; `/opt` is not used so host `/opt` mounts do not hide
it.

## Image Variants

Each image variant lives under:

```text
images/<base-os>/<desktop>/Dockerfile
```

The build context is the repository root so variants can reuse shared files
from `container/` and `vnc_novnc/`.

| Variant | Dockerfile | Published tag |
| --- | --- | --- |
| Debian 12 + fvwm3 | `images/debian-12/fvwm3/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:debian-12-main` |
| Debian 12 + XFCE | `images/debian-12/xfce/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:debian-12-xfce-main` |
| Ubuntu 24.04 + fvwm3 | `images/ubuntu-24.04/fvwm3/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-fvwm3-main` |
| Ubuntu 24.04 + XFCE | `images/ubuntu-24.04/xfce/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-xfce-main` |
| AlmaLinux 9 + fvwm3 | `images/alma-9/fvwm3/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:alma-9-fvwm3-main` |
| AlmaLinux 9 + XFCE | `images/alma-9/xfce/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:alma-9-xfce-main` |
| openSUSE Leap 15.6 + XFCE | `images/opensuse-15.6/xfce/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:opensuse-15.6-main` |

AlmaLinux 10 fvwm3 and XFCE Dockerfiles are scaffolded under `images/alma-10/`,
but they are not in CI yet. `podman-hpc run` package probes against AlmaLinux
10.2 with CRB and EPEL 10 enabled did not find TigerVNC server, fvwm3, or a full
XFCE desktop stack.

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
- `container/`: shared entrypoints and desktop config.
- `vnc_novnc/`: host and in-container Python helpers.
- `kernels/`: sample Jupyter kernelspec.
- `scripts/`: install and run helpers.

## Run A Desktop

The preferred runner is the Python helper:

```sh
scripts/run-vnc-novnc.py --config scripts/run-vnc-novnc.yaml
```

It starts the image with `podman-hpc`, generates a one-time VNC password, stores
the password in a temporary `0600` file, publishes only the noVNC port by
default, and prints the noVNC URL. It also generates a Jupyter Server Proxy URL
when it can determine the Jupyter user/server prefix.

The legacy shell helper is still available for the default image:

```sh
scripts/run-vnc-novnc.sh
```

The Python helper is more complete: it supports YAML defaults, image
preparation, bind mounts, environment passthrough, user namespace handling, and
extra `podman-hpc` arguments.

Example output:

```text
Image: ghcr.io/dingp/vnc-novnc-container:debian-12-main
noVNC: https://jupyter.nersc.gov/user/your-user-name/muller-login-node-base/proxy/49967/vnc.html?port=443&host=jupyter.nersc.gov&path=user%2Fyour-user-name%2Fmuller-login-node-base%2Fproxy%2F49967
One-time VNC password: AbC123xY
VNC server port is not exposed on the host.
```

Open the printed noVNC URL and enter the printed one-time VNC password.

## Runner Configuration

The included `scripts/run-vnc-novnc.yaml` uses `--userns=keep-id`,
`--group-add=keep-groups`, and bind mounts `$HOME`, `$SCRATCH`, and `$CFS` into
the same paths inside the container. Environment variables in YAML strings are
expanded on the host when the script starts.

YAML keys use long option names with underscores instead of dashes:

```yaml
userns: keep-id
keep_groups: true
pull_policy: missing

volume:
  - "${HOME}:${HOME}:rw"
  - "${SCRATCH}:${SCRATCH}:rw"
  - "${CFS}:${CFS}:rw"
```

Precedence is: built-in defaults, YAML config, environment variables, then
command-line arguments. Repeated list options such as `volume`, `mount`, `env`,
`group_add`, and `extra_podman_args` are initialized from YAML, and additional
command-line occurrences are appended.

Common settings:

| Variable | Default | Purpose |
| --- | --- | --- |
| `IMAGE` | `ghcr.io/dingp/vnc-novnc-container:debian-12-main` | Container image to run. |
| `HOST_NOVNC_ADDR` | `127.0.0.1` | Host address for noVNC port publication. |
| `HOST_NOVNC_PORT` | random | Host port for noVNC. |
| `NOVNC_PORT` | `6080` | noVNC port inside the container. |
| `VNC_PORT` | `5901` | VNC server port inside the container. |
| `EXPOSE_VNC` | `0` | Set to `1` to also publish the raw VNC server port. |
| `VNC_PASSWORD_LENGTH` | `8` | Length of the generated one-time VNC password. |

Common Python helper options:

| Option | Purpose |
| --- | --- |
| `--config FILE` | Read default values from a YAML config file. |
| `--image IMAGE` | Select a container image. |
| `--pull-policy POLICY` | Image preparation policy: `missing`, `newer`, `always`, or `never`. Default: `missing`. |
| `-v`, `--volume HOST:CONTAINER[:OPTIONS]` | Add a bind mount or volume spec. May be repeated. |
| `--mount SPEC` | Add a Podman `--mount` spec. May be repeated. |
| `-e`, `--env NAME[=VALUE]` | Pass an environment variable into the container. May be repeated. |
| `--userns=keep-id` | Pass `--userns=keep-id` to `podman-hpc`. |
| `--userns-keep-id` | Shorthand for `--userns=keep-id`. |
| `--group-add=keep-groups` | Pass `--group-add=keep-groups` to `podman-hpc`. |
| `--keep-groups` | Shorthand for `--group-add=keep-groups`. |
| `--expose-vnc` | Publish the raw VNC server port in addition to noVNC. |
| `--dry-run` | Print the generated command without running the container. |
| `--` | Pass following arguments directly to `podman-hpc run` before the image name. |

With `keep-id`, the Python helper also sets the generated container passwd entry
for the host UID to use `/bin/bash`.

## Pull Policy

The Python runner and Jupyter kernel wrapper use explicit image preparation:

- `missing` runs `podman-hpc image inspect` first and pulls only when the image
  is missing or local image metadata is not usable. This is the default.
- `newer` and `always` run `podman-hpc pull` before starting the container.
  They keep images fresher, but startup is slower and depends on registry
  availability.
- `never` never pulls and requires the image to already exist locally.

After any needed explicit pull, helpers start the container with
`podman-hpc run --pull=never`. This avoids failures seen when `podman-hpc run`
tries to pull and use a missing image in one step.

## Jupyter Server Proxy URLs

When run inside a Jupyter session, helpers use `JUPYTERHUB_SERVICE_PREFIX` to
build the proxied noVNC URL. This is the preferred path because JupyterHub
already provides the username and server name.

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

## Runner Examples

Use a fixed noVNC host port:

```sh
scripts/run-vnc-novnc.py --host-novnc-port 49967
```

Use another published variant:

```sh
scripts/run-vnc-novnc.py --image ghcr.io/dingp/vnc-novnc-container:opensuse-15.6-main
scripts/run-vnc-novnc.py --image ghcr.io/dingp/vnc-novnc-container:ubuntu-24.04-xfce-main
scripts/run-vnc-novnc.py --image ghcr.io/dingp/vnc-novnc-container:alma-9-xfce-main
```

Run outside Jupyter but still print a Jupyter proxy URL:

```sh
scripts/run-vnc-novnc.py --jupyter-proxy-server muller-login-node-base
```

Expose the raw VNC server port in addition to noVNC:

```sh
scripts/run-vnc-novnc.py --expose-vnc
```

Mount host directories into the container:

```sh
scripts/run-vnc-novnc.py \
  -v "${HOME}:${HOME}:rw" \
  -v "${SCRATCH}:${SCRATCH}:rw"
```

Pass extra `podman-hpc run` arguments:

```sh
scripts/run-vnc-novnc.py -- --ipc=host
```

## Jupyter Kernel

Install the default Debian 12 fvwm3 kernelspec:

```sh
scripts/install-jupyter-kernel.sh
```

This installs the Python package in editable mode for the current user and
copies the selected kernelspec into:

```text
${HOME}/.local/share/jupyter/kernels/vnc-novnc-DISTRO-DESKTOP
```

The default kernelspec directory is `vnc-novnc-debian12-fvwm3`; the display name
is `VNC-debian12-fvwm3`.

Useful installer options:

| Option | Purpose |
| --- | --- |
| `DISTRO DESKTOP` | Select the image variant, for example `ubuntu24.04 xfce` or `opensuse15.6 xfce`. |
| `--distro DISTRO`, `--desktop DESKTOP` | Select the same variant with explicit options. |
| `--all` | Install one kernelspec for every supported distro/desktop combination. |
| `--prepull` | Run `podman-hpc pull` for each selected image while installing kernelspecs. |
| `--podman-hpc COMMAND` | Choose the `podman-hpc` command used by `--prepull`. |
| `--source-wrapper` | Make the installed kernel wrapper import `vnc_novnc` directly from this checkout. |
| `--no-pip-install` | Copy the kernelspec without running `pip install`. |
| `--prefix DIR` | Install under `DIR/share/jupyter/kernels`. |
| `--name NAME` | Override the default kernelspec directory name. |
| `--display-name NAME` | Override the Jupyter display name. |
| `--force` | Replace an existing kernelspec directory. |
| `--list-variants` | Print supported distro/desktop combinations. |

Examples:

```sh
scripts/install-jupyter-kernel.sh ubuntu24.04 xfce --force
scripts/install-jupyter-kernel.sh opensuse15.6 xfce --force
scripts/install-jupyter-kernel.sh --all --force
scripts/install-jupyter-kernel.sh --all --prepull --force
```

For development from a checkout:

```sh
scripts/install-jupyter-kernel.sh --source-wrapper --force
```

Restart or refresh JupyterLab if the new kernel does not appear immediately.

## Kernel Behavior

When Jupyter starts a VNC/noVNC kernel, the host wrapper runs:

```sh
python3 -m vnc_novnc.kernel --config "{resource_dir}/vnc-novnc.yaml" -f "{connection_file}"
```

The wrapper:

- Chooses an available host port for noVNC unless `host_novnc_port` is set.
- Generates a one-time VNC password.
- Writes the password to a temporary `0600` file on the host.
- Mounts that file read-only at `/run/secrets/vnc-password` inside the
  container.
- Publishes noVNC on the selected host port.
- Names the container and explicitly stops/removes it if the host wrapper
  receives `INT`, `TERM`, or `HUP`.
- Uses `podman-hpc run --rm --jupyter`.
- Passes `--userns=keep-id` and `--group-add=keep-groups` from the YAML config.
- Adds a `--passwd-entry` for the host UID when `keep-id` is active so the
  notebook user resolves to `/bin/bash` inside the container.
- Mounts `$SCRATCH` and `$CFS` from the YAML config.
- Passes non-secret noVNC connection metadata into the container.

Inside the container, `vnc-novnc-jupyter-kernel` starts VNC/noVNC in the
background and then starts `ipykernel`. The image declares only the noVNC port
as exposed metadata; raw VNC remains internal unless a runner explicitly
publishes it.

After selecting a `VNC-DISTRO-DESKTOP` kernel, the noVNC URL and one-time
password are displayed automatically in the first notebook cell output. To show
them again manually:

```python
import vnc_novnc

vnc_novnc.display_connection()
```

The sample kernel config is `kernels/vnc-novnc/vnc-novnc.yaml`:

```yaml
image: ghcr.io/dingp/vnc-novnc-container:debian-12-main
userns: keep-id
keep_groups: true
pull_policy: missing

volume:
  - "${SCRATCH}:${SCRATCH}:rw"
  - "${CFS}:${CFS}:rw"
```

`$HOME` and `/tmp` are not listed in the kernel YAML because
`podman-hpc --jupyter` handles those mounts.

## Desktop Notes

The fvwm3 variants use `/etc/vnc-novnc/fvwm3-config` as the default config. On
startup, the entrypoint copies it to `${HOME}/.fvwm/config` only when that file
does not already exist. Existing configs are preserved, with a small migration
that rewrites old Chromium launcher commands to `/usr/local/bin/chromium`.

The Chromium wrapper is installed at `/usr/local/bin/chromium` in every image.
It adds `--no-sandbox` automatically when running as root.

## Add A New Variant

1. Create `images/<base-os>/<desktop>/Dockerfile`.
2. Reuse the shared entrypoints from `container/`.
3. Copy `vnc_novnc` into `/usr/local/lib/vnc-novnc/vnc_novnc`.
4. Set `PYTHONPATH=/usr/local/lib/vnc-novnc`.
5. Add a matrix entry in `.github/workflows/build-image.yaml`.
6. Add the variant to `scripts/install-jupyter-kernel.sh`.
7. Update this README with the new published tag.
