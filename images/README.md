# Image Variants

Each image variant lives under:

```text
images/<base-os>/<desktop>/Dockerfile
```

The build context is still the repository root so variants can reuse shared files from `container/` and `vnc_novnc/`.

| Variant | Dockerfile | Published tag |
| --- | --- | --- |
| Debian 12 + fvwm3 | `images/debian-12/fvwm3/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:debian-12-main` |
| openSUSE Leap 15.6 + XFCE | `images/opensuse-15.6/xfce/Dockerfile` | `ghcr.io/dingp/vnc-novnc-container:opensuse-15.6-main` |

To add a new variant:

1. Create `images/<base-os>/<desktop>/Dockerfile`.
2. Reuse the shared entrypoints from `container/`.
3. Copy `vnc_novnc` into `/usr/local/lib/vnc-novnc/vnc_novnc`.
4. Set `PYTHONPATH=/usr/local/lib/vnc-novnc`.
5. Add a matrix entry in `.github/workflows/build-image.yaml`.
