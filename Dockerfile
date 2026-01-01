FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    SCREEN_RESOLUTION=1280x720 \
    DISPLAY=:99 \
    TOR_VER=14.0.4

RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb x11vnc openbox python3-websockify python3-numpy \
    curl git ca-certificates xz-utils libgtk-3-0 \
    libdbus-glib-1-2 libxt6 libx11-xcb1 procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash toruser

# Setup noVNC and the Keyboard button fix
RUN mkdir -p /app && \
    git clone --depth 1 https://github.com/novnc/noVNC.git /app/novnc && \
    git clone --depth 1 https://github.com/novnc/websockify /app/novnc/utils/websockify && \
    cp /app/novnc/vnc.html /app/novnc/index.html && \
    sed -i 's|</body>|<div id="mobile-keyboard-toggle" style="position: fixed; bottom: 20px; right: 20px; z-index: 9999;"><button type="button" onclick="document.getElementById('\''noVNC_keyboard_button'\'').click()" style="padding: 15px 20px; font-size: 24px; background: #007bff; color: white; border: none; border-radius: 50px; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">⌨️ Keyboard</button></div></body>|' /app/novnc/index.html

# Download Tor Browser with a more reliable link
USER toruser
WORKDIR /home/toruser
RUN curl -sfL "https://dist.torproject.org/torbrowser/${TOR_VER}/tor-browser-linux-x86_64-${TOR_VER}.tar.xz" -o tor.tar.xz \
    && tar -xf tor.tar.xz \
    && rm tor.tar.xz \
    && mv tor-browser tor-browser-linux

COPY --chown=toruser:toruser start.sh /home/toruser/start.sh
RUN chmod +x /home/toruser/start.sh

EXPOSE 8080
CMD ["/home/toruser/start.sh"]
