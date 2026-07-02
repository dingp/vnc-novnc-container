# Image Variants

Each image variant lives under:

```text
images/<base-os>/<desktop>/Dockerfile
```

The build context is still the repository root so variants can reuse shared files from `container/` and `vnc_novnc/`.

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

To add a new variant:

1. Create `images/<base-os>/<desktop>/Dockerfile`.
2. Reuse the shared entrypoints from `container/`.
3. Copy `vnc_novnc` into `/usr/local/lib/vnc-novnc/vnc_novnc`.
4. Set `PYTHONPATH=/usr/local/lib/vnc-novnc`.
5. Add a matrix entry in `.github/workflows/build-image.yaml`.
