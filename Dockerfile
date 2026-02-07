FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    VNC_RESOLUTION=1920x1080 \
    VNC_COL_DEPTH=24 \
    VNC_PASSWORD=dappnode \
    USER=desktop \
    HOME=/home/desktop

# Enable universe repository (required for tigervnc)
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && apt-get update

# Install base system + MATE desktop
RUN apt-get install -y --no-install-recommends \
    # Core system
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    xauth \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    # noVNC + websockify
    novnc \
    websockify \
    # Useful apps & utilities
    sudo \
    wget \
    curl \
    git \
    nano \
    vim \
    htop \
    net-tools \
    iputils-ping \
    locales \
    fonts-noto \
    fonts-noto-color-emoji \
    pulseaudio \
    dbus \
    libatomic1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install MATE desktop separately (large layer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ubuntu-mate-desktop \
    mate-terminal \
    mate-applet-brisk-menu \
    pluma \
    atril \
    engrampa \
    caja \
    eom \
    mate-calc \
    mate-system-monitor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Brave browser (multi-arch support)
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
    && echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        > /etc/apt/sources.list.d/brave-browser-release.list \
    && apt-get update \
    && apt-get install -y brave-browser \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Verify VNC binaries are installed
RUN which vncserver && which vncpasswd && vncserver -version || \
    (echo "ERROR: TigerVNC binaries not found!" && exit 1)

# Create non-root user with sudo
RUN useradd -m -s /bin/bash -G sudo,adm,video,audio ${USER} \
    && echo "${USER}:${VNC_PASSWORD}" | chpasswd \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER}

# Link noVNC files
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Install custom panel layout (no indicator applets) and set as default
COPY config/container.layout /usr/share/mate-panel/layouts/container.layout
RUN sed -i 's/\r$//' /usr/share/mate-panel/layouts/container.layout \
    && echo '[org.mate.panel]' > /usr/share/glib-2.0/schemas/90_mate-panel-container.gschema.override \
    && echo "default-layout='container'" >> /usr/share/glib-2.0/schemas/90_mate-panel-container.gschema.override \
    && glib-compile-schemas /usr/share/glib-2.0/schemas/

# Copy startup script
COPY scripts/startup.sh /opt/startup.sh
RUN sed -i 's/\r$//' /opt/startup.sh && chmod +x /opt/startup.sh

# Copy persist-install helper
COPY scripts/persist-install.sh /usr/local/bin/persist-install
RUN sed -i 's/\r$//' /usr/local/bin/persist-install && chmod +x /usr/local/bin/persist-install

# Copy VNC xstartup
COPY scripts/xstartup /opt/xstartup
RUN sed -i 's/\r$//' /opt/xstartup && chmod +x /opt/xstartup

# Expose ports
EXPOSE ${VNC_PORT} ${NOVNC_PORT}

# Home directory is the volume mount point
VOLUME /home/desktop

ENTRYPOINT ["/opt/startup.sh"]
