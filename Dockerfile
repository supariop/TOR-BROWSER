FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

# Install packages
RUN apt update && apt install -y \
    wget curl sudo \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server \
    dbus-x11 \
    xauth x11-xserver-utils \
    python3 net-tools \
    supervisor \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Tor Browser
RUN wget https://www.torproject.org/dist/torbrowser/14.0.1/tor-browser-linux-x86_64-14.0.1.tar.xz -O /tmp/tor.tar.xz && \
    tar -xf /tmp/tor.tar.xz -C /opt && \
    mv /opt/tor-browser* /opt/tor-browser && \
    rm /tmp/tor.tar.xz

# Create VNC user and set password
RUN useradd -m -s /bin/bash user && \
    echo "user:user" | chpasswd && \
    mkdir -p /home/user/.vnc && \
    printf "Clown80990@\nClown80990@\n" | vncpasswd -f > /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc && \
    chmod 600 /home/user/.vnc/passwd

# VNC xstartup
RUN bash -c "cat > /home/user/.vnc/xstartup << 'EOF'\n\
#!/bin/bash\n\
xrdb \$HOME/.Xresources\n\
startxfce4 &\n\
EOF"

RUN chmod +x /home/user/.vnc/xstartup

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Supervisor config
RUN mkdir -p /etc/supervisor/conf.d && \
    echo "[supervisord]\n\
nodaemon=true\n\
\n\
[program:vnc]\n\
command=/usr/bin/vncserver :1 -geometry 1280x720 -localhost no\n\
user=user\n\
\n\
[program:novnc]\n\
command=/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 8080\n\
directory=/opt/noVNC\n\
user=user\n" > /etc/supervisor/conf.d/supervisor.conf

# Expose noVNC port
EXPOSE 8080

# Start supervisor
CMD ["/usr/bin/supervisord"]
