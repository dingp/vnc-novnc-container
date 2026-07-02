FROM docker.io/almalinux:9-minimal

ARG TARGETARCH
ARG SSHPROXY_VERSION=2.1.2
ARG SSHPROXY_ARCH

RUN \
    set -eu; \
    case "${SSHPROXY_ARCH:-${TARGETARCH:-amd64}}" in \
        amd64|x86_64|linux-x86_64) sshproxy_arch=linux-x86_64 ;; \
        *) echo "AlmaLinux desktop variant currently supports amd64 only: ${SSHPROXY_ARCH:-${TARGETARCH:-}}" >&2; exit 1 ;; \
    esac; \
    sshproxy_url="https://portal.nersc.gov/cfs/mfa/sshproxy-${SSHPROXY_VERSION}-${sshproxy_arch}.tar.gz"; \
    microdnf -y install dnf dnf-plugins-core epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf -y install --allowerasing --setopt=install_weak_deps=False \
        ca-certificates \
        bash \
        chromium \
        curl \
        dbus-x11 \
        file \
        findutils \
        gcc \
        gdb \
        git \
        gzip \
        iproute \
        less \
        make \
        net-tools \
        nfs-utils \
        nmap \
        novnc \
        openssh-clients \
        openssh-server \
        openssl-devel \
        procps-ng \
        python3 \
        python3-pip \
        python3-websockify \
        tar \
        Thunar \
        tigervnc \
        tigervnc-server \
        tmux \
        tcpdump \
        vim \
        wireshark-cli \
        wget \
        which \
        xorg-x11-server-utils \
        xorg-x11-xauth \
        xterm \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xfce4-terminal \
        xfdesktop \
        xfwm4 \
        zlib-devel && \
    python3 -m pip install --no-cache-dir ipykernel && \
    curl --fail --location --show-error "${sshproxy_url}" --output /tmp/sshproxy.tar.gz && \
    tar -xzf /tmp/sshproxy.tar.gz -C /usr/local/bin sshproxy && \
    chmod 0755 /usr/local/bin/sshproxy && \
    mkdir -p /etc/vnc-novnc && \
    sed -i 's#^\(root:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\).*#\1/bin/bash#' /etc/passwd && \
    dnf clean all && \
    rm -rf /tmp/sshproxy.tar.gz /var/cache/dnf

COPY container/vnc/vnc-novnc-entrypoint /usr/local/bin/vnc-novnc-entrypoint
COPY container/kernel/vnc-novnc-jupyter-kernel /usr/local/bin/vnc-novnc-jupyter-kernel
COPY vnc_novnc /usr/local/lib/vnc-novnc/vnc_novnc

RUN \
    chmod 0755 /usr/local/bin/vnc-novnc-entrypoint /usr/local/bin/vnc-novnc-jupyter-kernel && \
    chmod -R a+rX /usr/local/lib/vnc-novnc && \
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "$(id -u)" = "0" ]; then' \
        '    exec /usr/bin/chromium-browser --no-sandbox "$@"' \
        'fi' \
        'exec /usr/bin/chromium-browser "$@"' \
        > /usr/local/bin/chromium && \
    chmod 0755 /usr/local/bin/chromium

ENV \
    VNC_DISPLAY=1 \
    VNC_PORT=5901 \
    VNC_GEOMETRY=1280x800 \
    VNC_DEPTH=24 \
    VNC_LOCALHOST=no \
    VNC_SECURITY_TYPES=VncAuth \
    VNC_PASSWORD=changeme \
    VNC_PASSWORD_FILE=/root/.vnc/passwd \
    VNC_PASSWORD_PLAIN_FILE= \
    VNC_XSTARTUP=/root/.vnc/xstartup \
    VNC_DESKTOP_CMD=startxfce4 \
    VNC_EXTRA_ARGS= \
    NOVNC_LISTEN=0.0.0.0 \
    NOVNC_PORT=6080 \
    NOVNC_WEB=/usr/share/novnc \
    NOVNC_VNC_HOST=127.0.0.1 \
    NOVNC_VNC_PORT= \
    NOVNC_EXTRA_ARGS= \
    SHELL=/bin/bash \
    PYTHONPATH=/usr/local/lib/vnc-novnc

EXPOSE 6080

ENTRYPOINT ["/usr/local/bin/vnc-novnc-entrypoint"]
CMD ["start"]
