FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV USER=user
ENV HOME=/home/user

# -------------------------------------------------
# Install minimal required packages
# -------------------------------------------------
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
    jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------
# Create non-root user
# -------------------------------------------------
RUN useradd -m -s /bin/bash user

# -------------------------------------------------
# Download LATEST Tor Browser (API-based, future-proof)
# -------------------------------------------------
RUN set -eux; \
    cd /tmp; \
    TOR_URL=$(curl -s https://aus1.torproject.org/torbrowser/update_3/release/downloads.json \
      | jq -r '.downloads.linux64[] | select(.binary=="tor-browser-linux64") | .url' \
      | head -n 1); \
    echo "Downloading: $TOR_URL"; \
    wget "$TOR_URL"; \
    tar -xf tor-browser-linux64-*.tar.xz; \
    mv tor-browser /home/user/tor-browser; \
    rm tor-browser-linux64-*.tar.xz; \
    chown -R user:user /home/user/tor-browser

# -------------------------------------------------
# Install noVNC + websockify
# -------------------------------------------------
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# -------------------------------------------------
# VNC + Openbox startup config
# -------------------------------------------------
RUN mkdir -p /home/user/.vnc && \
    echo '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec openbox-session &' \
    > /home/user/.vnc/xstartup && \
    chmod +x /home/user/.vnc/xstartup && \
    chown -R user:user /home/user/.vnc

# -------------------------------------------------
# LOW-RAM Tor Browser tuning (safe)
# -------------------------------------------------
RUN mkdir -p /home/user/.tor-browser-profile && \
    echo '\
user_pref("media.autoplay.default", 5);\n\
user_pref("media.ffmpeg.enabled", false);\n\
user_pref("media.webrtc.enabled", false);\n\
user_pref("browser.cache.memory.enable", false);\n\
user_pref("browser.sessionstore.interval", 600000);\n\
user_pref("ui.prefersReducedMotion", 1);\n\
user_pref("dom.ipc.processCount", 1);\n' \
    > /home/user/.tor-browser-profile/user.js && \
    chown -R user:user /home/user/.tor-browser-profile

# -------------------------------------------------
# Switch to non-root user
# -------------------------------------------------
USER user
WORKDIR /home/user

# -------------------------------------------------
# Set VNC password (CHANGE THIS)
# -------------------------------------------------
RUN printf "password\npassword\n\n" | vncpasswd

# -------------------------------------------------
# Expose only noVNC
# -------------------------------------------------
EXPOSE 6080

# -------------------------------------------------
# Start Openbox + Tuned Tor + noVNC
# -------------------------------------------------
CMD vncserver :1 -geometry 1280x720 -depth 24 && \
    sleep 2 && \
    TOR_SKIP_LAUNCH=1 \
    /home/user/tor-browser/Browser/firefox \
      --profile /home/user/.tor-browser-profile \
      --disable-gpu \
      --no-sandbox \
      --disable-dev-shm-usage \
      & \
    /opt/novnc/utils/novnc_proxy \
      --vnc localhost:5901 \
      --listen 0.0.0.0:6080
