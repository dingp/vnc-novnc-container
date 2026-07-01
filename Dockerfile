From debian:12

ENV DEBIAN_FRONTEND noninteractive

ARG SSHPROXY_VERSION=2.1.2
ARG SSHPROXY_ARCH=linux-x86_64
ARG SSHPROXY_URL=https://portal.nersc.gov/cfs/mfa/sshproxy-${SSHPROXY_VERSION}-${SSHPROXY_ARCH}.tar.gz

RUN \
    apt-get update        &&   \
    apt-get install --yes --no-install-recommends \
        ca-certificates       \
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
    curl --fail --location --show-error "${SSHPROXY_URL}" --output /tmp/sshproxy.tar.gz && \
    tar -xzf /tmp/sshproxy.tar.gz -C /usr/local/bin sshproxy && \
    chmod 0755 /usr/local/bin/sshproxy && \
    mkdir -p /etc/vnc-novnc /root/.fvwm  &&   \
    apt-get clean         &&   \
    rm -rf /var/lib/apt/lists/* /tmp/sshproxy.tar.gz

COPY container/vnc/vnc-novnc-entrypoint /usr/local/bin/vnc-novnc-entrypoint
COPY container/kernel/vnc-novnc-jupyter-kernel /usr/local/bin/vnc-novnc-jupyter-kernel
COPY container/vnc/fvwm3-config /etc/vnc-novnc/fvwm3-config
COPY container/vnc/fvwm3-config /root/.fvwm/config
COPY vnc_novnc /opt/vnc-novnc/vnc_novnc

RUN \
    chmod 0755 /usr/local/bin/vnc-novnc-entrypoint /usr/local/bin/vnc-novnc-jupyter-kernel && \
    chmod -R a+rX /opt/vnc-novnc && \
    printf '%s\n' \
        '#!/bin/sh' \
        'if [ "$(id -u)" = "0" ]; then' \
        '    exec chromium --no-sandbox "$@"' \
        'fi' \
        'exec chromium "$@"' \
        > /usr/local/bin/chrome && \
    chmod 0755 /usr/local/bin/chrome

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
    PYTHONPATH=/opt/vnc-novnc

EXPOSE 5901 6080

ENTRYPOINT ["/usr/local/bin/vnc-novnc-entrypoint"]
CMD ["start"]
