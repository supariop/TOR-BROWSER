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
    netcat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------
# Create non-root user
# ------------------------------
RUN useradd -m -s /bin/bash user

# ------------------------------
# Install noVNC + websockify
# ------------------------------
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# ------------------------------
# VNC + Openbox startup config (FIXED)
# ------------------------------
RUN mkdir -p /home/user/.vnc && \
    cat << 'EOF' > /home/user/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec openbox-session
EOF
RUN chmod +x /home/user/.vnc/xstartup && \
    chown -R user:user /home/user/.vnc

# ------------------------------
# Switch to non-root user
# ------------------------------
USER user
WORKDIR /home/user

# ------------------------------
# Set VNC password safely
# Password: Clown80990@
# ------------------------------
RUN mkdir -p /home/user/.vnc && \
    printf "Clown80990@\nClown80990@\n\n" | vncpasswd && \
    chmod 600 /home/user/.vnc/passwd

# ------------------------------
# Expose noVNC port
# ------------------------------
EXPOSE 6080

# ------------------------------
# Start VNC → wait → noVNC → Tor Browser
# ------------------------------
CMD bash -c "\
vncserver :1 -geometry 1280x720 -depth 24 && \
echo 'Waiting for VNC to be ready...' && \
while ! nc -z localhost 5901; do sleep 1; done && \
echo 'Starting noVNC...' && \
/opt/novnc/utils/novnc_proxy \
  --vnc localhost:5901 \
  --listen 0.0.0.0:6080 \
  --web /opt/novnc & \
echo 'Starting Tor Browser...' && \
torbrowser-launcher"
