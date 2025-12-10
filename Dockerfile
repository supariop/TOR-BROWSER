FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt update && apt install -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    novnc websockify \
    supervisor wget curl git \
    dbus-x11 x11-xserver-utils \
    python3 python3-pip \
    && apt clean

# Create user
RUN useradd -m user && echo "user:user" | chpasswd

# Install Tor Browser (stable working version)
RUN mkdir /opt/tor && \
    wget -O /opt/tor-browser.tar.xz https://dist.torproject.org/torbrowser/13.5.2/tor-browser-linux64-13.5.2.tar.xz && \
    tar -xf /opt/tor-browser.tar.xz -C /opt/tor --strip-components=1 && \
    rm /opt/tor-browser.tar.xz && \
    chown -R user:user /opt/tor

# Setup VNC password
RUN mkdir -p /home/user/.vnc && \
    echo "Clown80990@" | vncpasswd -f > /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

# Install noVNC
RUN git clone https://github.com/novnc/noVNC /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

EXPOSE 8080

# Supervisor configuration
RUN bash -c "cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true

[program:vnc]
command=/usr/bin/vncserver :1 -geometry 1280x720 -localhost no
user=user

[program:novnc]
command=/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 8080
directory=/opt/noVNC
user=user
EOF"

# Start XFCE desktop
RUN bash -c "echo '#!/bin/bash\nstartxfce4 &' > /home/user/.vnc/xstartup" && \
    chmod +x /home/user/.vnc/xstartup && \
    chown user:user /home/user/.vnc/xstartup

CMD ["/usr/bin/supervisord"]
