FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV USER=user
ENV HOME=/home/user

# ------------------------------
# Install required packages
# ------------------------------
RUN apt-get update && apt-get install -y \
    openbox \
    xterm \
    tigervnc-standalone-server \
    tigervnc-common \
    x11-xserver-utils \
    xfonts-base \
    torbrowser-launcher \
    wget \
    curl \
    ca-certificates \
    git \
    python3 \
    dbus-x11 \
    jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------
# Create non-root user
# ------------------------------
RUN useradd -m -s /bin/bash $USER

# ------------------------------
# Install noVNC + websockify
# ------------------------------
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# ------------------------------
# VNC + Openbox startup config
# ------------------------------
RUN mkdir -p $HOME/.vnc && \
    echo '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexec openbox-session &' \
    > $HOME/.vnc/xstartup && \
    chmod +x $HOME/.vnc/xstartup && \
    chown -R $USER:$USER $HOME/.vnc

# ------------------------------
# LOW-RAM Tor Browser tuning
# ------------------------------
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

# ------------------------------
# Switch to non-root user
# ------------------------------
USER $USER
WORKDIR $HOME

# ------------------------------
# Set VNC password safely
# ------------------------------
RUN mkdir -p $HOME/.vnc && \
    printf "Clown80990@\nClown80990@\n\n" | vncpasswd && \
    chmod 600 $HOME/.vnc/passwd

# ------------------------------
# Expose noVNC port
# ------------------------------
EXPOSE 6080

# ------------------------------
# CMD: Robust startup
# ------------------------------
CMD bash -c "\
vncserver :1 -geometry 1280x720 -depth 24 && \
echo 'Waiting for VNC server to be ready...' && \
while ! nc -z localhost 5901; do sleep 1; done && \
echo 'VNC is ready, starting noVNC...' && \
/opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:6080 --web /opt/novnc & \
sleep 2 && \
echo 'Starting Tor Browser...' && \
torbrowser-launcher --profile $HOME/.tor-browser-profile --disable-gpu --no-sandbox & \
wait"
