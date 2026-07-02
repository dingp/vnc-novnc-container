FROM debian:12

ENV DEBIAN_FRONTEND noninteractive

ARG TARGETARCH
ARG SSHPROXY_VERSION=2.1.2
ARG SSHPROXY_ARCH

RUN \
    set -eu; \
    case "${SSHPROXY_ARCH:-${TARGETARCH:-amd64}}" in \
        amd64|x86_64|linux-x86_64) sshproxy_arch=linux-x86_64 ;; \
        arm64|aarch64|linux-aarch64) sshproxy_arch=linux-aarch64 ;; \
        *) echo "Unsupported sshproxy architecture: ${SSHPROXY_ARCH:-${TARGETARCH:-}}" >&2; exit 1 ;; \
    esac; \
    sshproxy_url="https://portal.nersc.gov/cfs/mfa/sshproxy-${SSHPROXY_VERSION}-${sshproxy_arch}.tar.gz"; \
    apt-get update        &&   \
    apt-get install --yes --no-install-recommends \
        ca-certificates       \
        bash                  \
        curl                  \
        dbus-x11              \
        file                  \
        findutils             \
        fvwm3                 \
        git                   \
        iproute2              \
        less                  \
        net-tools             \
        novnc                 \
        openssh-client        \
        procps                \
        python3               \
        python3-ipykernel     \
        tar                   \
        thunar                \
        tigervnc-standalone-server \
        tigervnc-tools        \
        tmux                  \
        vim                   \
        wget                  \
        websockify            \
        x11-xserver-utils     \
        xauth                 \
        xfonts-base           \
        xterm                 \
        xfce4-terminal        \
        chromium              \
        chromium-sandbox  &&  \
    curl --fail --location --show-error "${sshproxy_url}" --output /tmp/sshproxy.tar.gz && \
    tar -xzf /tmp/sshproxy.tar.gz -C /usr/local/bin sshproxy && \
    chmod 0755 /usr/local/bin/sshproxy && \
    mkdir -p /etc/vnc-novnc /root/.fvwm  &&   \
    sed -i 's#^\(root:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\).*#\1/bin/bash#' /etc/passwd && \
    apt-get clean         &&   \
    rm -rf /var/lib/apt/lists/* /tmp/sshproxy.tar.gz

COPY container/vnc/vnc-novnc-entrypoint /usr/local/bin/vnc-novnc-entrypoint
COPY container/kernel/vnc-novnc-jupyter-kernel /usr/local/bin/vnc-novnc-jupyter-kernel
COPY container/vnc/fvwm3-config /etc/vnc-novnc/fvwm3-config
COPY container/vnc/fvwm3-config /root/.fvwm/config
COPY vnc_novnc /usr/local/lib/vnc-novnc/vnc_novnc

RUN \
    chmod 0755 /usr/local/bin/vnc-novnc-entrypoint /usr/local/bin/vnc-novnc-jupyter-kernel && \
    chmod -R a+rX /usr/local/lib/vnc-novnc && \
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "$(id -u)" = "0" ]; then' \
        '    exec /usr/bin/chromium --no-sandbox "$@"' \
        'fi' \
        'exec /usr/bin/chromium "$@"' \
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
    VNC_DESKTOP_CMD=fvwm3 \
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
