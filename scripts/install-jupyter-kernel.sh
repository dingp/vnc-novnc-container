#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/install-jupyter-kernel.sh [OPTIONS]

Install the VNC/noVNC podman-hpc Jupyter kernelspec for the current user.

Options:
  --name NAME             Kernelspec directory name. Default: vnc-novnc
  --display-name NAME     Kernel display name shown in Jupyter.
                          Default: Debian VNC/noVNC (podman-hpc)
  --prefix DIR            Jupyter prefix. Installs to DIR/share/jupyter/kernels/NAME.
                          Default: ${HOME}/.local
  --no-pip-install        Do not run "python3 -m pip install --user -e .".
  --source-wrapper        Install a wrapper that imports vnc_novnc from this checkout.
  --force                 Replace an existing kernelspec directory.
  -h, --help              Show this help.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"

kernel_name="vnc-novnc"
display_name="Debian VNC/noVNC (podman-hpc)"
prefix="${HOME}/.local"
pip_install=1
source_wrapper=0
force=0

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --name)
            kernel_name="${2:?--name requires a value}"
            shift 2
            ;;
        --display-name)
            display_name="${2:?--display-name requires a value}"
            shift 2
            ;;
        --prefix)
            prefix="${2:?--prefix requires a value}"
            shift 2
            ;;
        --no-pip-install)
            pip_install=0
            shift
            ;;
        --source-wrapper)
            source_wrapper=1
            shift
            ;;
        --force)
            force=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

kernel_src="${repo_dir}/kernels/vnc-novnc"
kernel_dst="${prefix}/share/jupyter/kernels/${kernel_name}"

if [[ ! -f "${kernel_src}/kernel.json" ]]; then
    printf 'Missing sample kernelspec: %s\n' "${kernel_src}/kernel.json" >&2
    exit 1
fi

if [[ -e "${kernel_dst}" && "${force}" -ne 1 ]]; then
    printf 'Kernelspec already exists: %s\n' "${kernel_dst}" >&2
    printf 'Re-run with --force to replace it.\n' >&2
    exit 1
fi

if [[ "${pip_install}" -eq 1 ]]; then
    python3 -m pip install --user -e "${repo_dir}"
fi

tmpdir="$(mktemp -d)"
cleanup() {
    rm -rf "${tmpdir}"
}
trap cleanup EXIT

mkdir -p "${tmpdir}/${kernel_name}"
cp "${kernel_src}/kernel.json" "${tmpdir}/${kernel_name}/"
cp "${kernel_src}/kernel-wrapper" "${tmpdir}/${kernel_name}/"
cp "${kernel_src}/vnc-novnc.yaml" "${tmpdir}/${kernel_name}/"

python3 - "${tmpdir}/${kernel_name}/kernel.json" "${display_name}" <<'PY'
import json
import sys

path, display_name = sys.argv[1:3]
with open(path) as handle:
    data = json.load(handle)
data["display_name"] = display_name
with open(path, "w") as handle:
    json.dump(data, handle, indent=2)
    handle.write("\n")
PY

if [[ "${source_wrapper}" -eq 1 ]]; then
    cat > "${tmpdir}/${kernel_name}/kernel-wrapper" <<EOF
#!/bin/sh
export PYTHONPATH="${repo_dir}:\${PYTHONPATH:-}"
exec python3 -m vnc_novnc.kernel "\$@"
EOF
fi

chmod 0755 "${tmpdir}/${kernel_name}/kernel-wrapper"
mkdir -p "$(dirname "${kernel_dst}")"
rm -rf "${kernel_dst}"
cp -R "${tmpdir}/${kernel_name}" "${kernel_dst}"

printf 'Installed kernelspec: %s\n' "${kernel_dst}"
printf 'Kernel display name: %s\n' "${display_name}"
printf 'Config file: %s\n' "${kernel_dst}/vnc-novnc.yaml"
printf 'To verify visible kernels, run: jupyter kernelspec list\n'
