FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    x11vnc xvfb \
    tigervnc-standalone-server \
    novnc websockify \
    supervisor \
    wget curl \
    dbus-x11 \
    && apt-get clean

# Create user
RUN useradd -m user && echo "user:user" | chpasswd

# Install Tor Browser (VALID URL)
RUN mkdir /opt/tor && \
    wget -O /opt/tor-browser.tar.xz https://dist.torproject.org/torbrowser/13.0.13/tor-browser-linux-x86_64-13.0.13.tar.xz && \
    tar -xf /opt/tor-browser.tar.xz -C /opt/tor --strip-components=1 && \
    rm /opt/tor-browser.tar.xz && \
    chown -R user:user /opt/tor

# Set VNC password
RUN mkdir -p /home/user/.vnc && \
    x11vnc -storepasswd "Clown80990@" /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

# Create xstartup (NO INDENTATION VERSION — FIXED)
RUN cat << 'EOF' > /home/user/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF

RUN chmod +x /home/user/.vnc/xstartup

# Supervisor config (ALSO NO INDENTATION — FIXED)
RUN mkdir -p /etc/supervisor/conf.d

RUN cat << 'EOF' > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true

[program:vnc]
command=/usr/bin/x11vnc -forever -usepw -create -display :1 -rfbport 5901
user=user
autorestart=true

[program:novnc]
command=/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 10000
directory=/usr/share/novnc
user=user
autorestart=true
EOF

EXPOSE 10000
CMD ["/usr/bin/supervisord"]
