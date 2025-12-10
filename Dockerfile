FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
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

# Install Tor Browser
RUN mkdir /opt/tor && \
    wget -O /opt/tor-browser.tar.xz https://dist.torproject.org/torbrowser/13.5.2/tor-browser-linux64-13.5.2.tar.xz && \
    tar -xf /opt/tor-browser.tar.xz -C /opt/tor --strip-components=1 && \
    rm /opt/tor-browser.tar.xz && \
    chown -R user:user /opt/tor

# Set VNC password
RUN mkdir -p /home/user/.vnc && \
    echo "Clown80990@" | vncpasswd -f > /home/user/.vnc/passwd && \
    chmod 600 /home/user/.vnc/passwd && \
    chown -R user:user /home/user/.vnc

# Install noVNC
RUN git clone https://github.com/novnc/noVNC /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Supervisor config (SAFE echo only)
RUN mkdir -p /etc/supervisor/conf.d

RUN echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:vnc]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/usr/bin/vncserver :1 -geometry 1280x720 -localhost no" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "user=user" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "[program:novnc]" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "command=/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 8080" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "directory=/opt/noVNC" >> /etc/supervisor/conf.d/supervisord.conf && \
    echo "user=user" >> /etc/supervisor/conf.d/supervisord.conf

# xstartup (NO HEREDOC)
RUN echo "#!/bin/bash" > /home/user/.vnc/xstartup && \
    echo "xrdb \$HOME/.Xresources" >> /home/user/.vnc/xstartup && \
    echo "startxfce4 &" >> /home/user/.vnc/xstartup && \
    chmod +x /home/user/.vnc/xstartup && \
    chown user:user /home/user/.vnc/xstartup

EXPOSE 8080

CMD ["/usr/bin/supervisord"]
