FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    x11vnc xvfb \
    supervisor \
    wget curl \
    novnc websockify \
    tigervnc-standalone-server \
    dbus-x11 \
    && apt-get clean

# Create user
RUN useradd -m user && echo "user:user" | chpasswd && adduser user sudo

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

# Create startup script
RUN bash -c 'cat << EOF > /home/user/.vnc/xstartup
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF'
RUN chmod +x /home/user/.vnc/xstartup && chown -R user:user /home/user/.vnc

# Supervisor config
RUN mkdir -p /etc/supervisor/conf.d && \
    bash -c 'cat << EOF > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true

[program:vnc]
command=/usr/bin/x11vnc -forever -usepw -create -display :1 -rfbport 5901
user=user
priority=1
autorestart=true

[program:novnc]
command=/usr/share/novnc/utils/launch.sh --vnc localhost:5901 --listen 8080
directory=/usr/share/novnc
user=user
priority=2
autorestart=true
EOF'

EXPOSE 8080
CMD ["/usr/bin/supervisord"]
