FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV USER=user
ENV HOME=/home/user

# Install minimal packages
RUN apt-get update && apt-get install -y \
    openbox \
    xterm \
    tigervnc-standalone-server \
    tigervnc-common \
    x11-xserver-utils \
    xfonts-base \
    wget \
    curl \
    ca-certificates \
    git \
    python3 \
    dbus-x11 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash $USER

# Download Tor Browser (official)
RUN wget -q https://www.torproject.org/dist/torbrowser/13.0.10/tor-browser-linux64-13.0.10.tar.xz \
    && tar -xf tor-browser-linux64-13.0.10.tar.xz \
    && mv tor-browser $HOME/tor-browser \
    && rm tor-browser-linux64-13.0.10.tar.xz \
    && chown -R $USER:$USER $HOME/tor-browser

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# VNC + Openbox startup
RUN mkdir -p $HOME/.vnc && \
    echo '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec openbox-session &' \
    > $HOME/.vnc/xstartup && \
    chmod +x $HOME/.vnc/xstartup && \
    chown -R $USER:$USER $HOME/.vnc

# ---- Tor Browser LOW-RAM tuning ----
RUN mkdir -p $HOME/.tor-browser-profile && \
    echo '\
user_pref("media.autoplay.default", 5);\n\
user_pref("media.ffmpeg.enabled", false);\n\
user_pref("media.webrtc.enabled", false);\n\
user_pref("browser.cache.memory.enable", false);\n\
user_pref("browser.sessionstore.interval", 600000);\n\
user_pref("ui.prefersReducedMotion", 1);\n\
user_pref("dom.ipc.processCount", 1);\n' \
    > $HOME/.tor-browser-profile/user.js && \
    chown -R $USER:$USER $HOME/.tor-browser-profile

# Switch to user
USER $USER
WORKDIR $HOME

# Set VNC password
RUN printf "password\npassword\n\n" | vncpasswd

# Expose noVNC only
EXPOSE 6080

# Start everything (with low-RAM flags)
CMD vncserver :1 -geometry 1280x720 -depth 24 && \
    sleep 2 && \
    TOR_SKIP_LAUNCH=1 \
    $HOME/tor-browser/Browser/firefox \
      --profile $HOME/.tor-browser-profile \
      --disable-gpu \
      --no-sandbox \
      --disable-dev-shm-usage \
      & \
    /opt/novnc/utils/novnc_proxy \
      --vnc localhost:5901 \
      --listen 0.0.0.0:6080
