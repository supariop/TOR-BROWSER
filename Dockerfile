FROM debian:stable-slim

# System setup
ENV DEBIAN_FRONTEND=noninteractive \
    SCREEN_RESOLUTION=1280x720 \
    DISPLAY=:99

# Install dependencies (Lighter selection)
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb x11vnc openbox python3-websockify python3-numpy \
    curl git ca-certificates xz-utils libgtk-3-0 \
    libdbus-glib-1-2 libxt6 libx11-xcb1 procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash toruser

# Setup noVNC with Mobile Keyboard Button
RUN mkdir -p /app && \
    git clone --depth 1 https://github.com/novnc/noVNC.git /app/novnc && \
    git clone --depth 1 https://github.com/novnc/websockify /app/novnc/utils/websockify && \
    cp /app/novnc/vnc.html /app/novnc/index.html && \
    sed -i 's|</body>|<div id="mobile-keyboard-toggle" style="position: fixed; bottom: 20px; right: 20px; z-index: 9999;"><button type="button" onclick="document.getElementById('\''noVNC_keyboard_button'\'').click()" style="padding: 15px 20px; font-size: 24px; background: #007bff; color: white; border: none; border-radius: 50px; box-shadow: 0 4px 6px rgba(0,0,0,0.3);">⌨️ Keyboard</button></div></body>|' /app/novnc/index.html

# Download Tor 11.5.0
USER toruser
WORKDIR /home/toruser
RUN curl -sfL "https://archive.torproject.org/tor-package-archive/torbrowser/11.5/tor-browser-linux64-11.5_en-US.tar.xz" -o tor.tar.xz \
    && tar -xf tor.tar.xz \
    && rm tor.tar.xz \
    && mv tor-browser_en-US tor-browser-linux

# Disable Auto-Update to save RAM and stay on 11.5.0
RUN echo 'pref("app.update.auto", false);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js && \
    echo 'pref("app.update.enabled", false);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js

COPY --chown=toruser:toruser start.sh /home/toruser/start.sh
RUN chmod +x /home/toruser/start.sh

EXPOSE 8080
CMD ["/home/toruser/start.sh"]
