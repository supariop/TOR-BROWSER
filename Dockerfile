# Use a slim Debian base
FROM debian:stable-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SCREEN_RESOLUTION=1280x720
ENV DISPLAY=:99

# Install dependencies
# We removed 'novnc' from apt and added 'git' and 'net-tools' to get the latest version manually
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    openbox \
    python3-websockify \
    python3-numpy \
    curl \
    git \
    ca-certificates \
    gpg \
    xz-utils \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libxt6 \
    libx11-xcb1 \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash toruser

# Setup directories and download LATEST noVNC directly from GitHub
# The apt version is often old; this ensures you get the best mobile support
RUN mkdir -p /app && \
    git clone --depth 1 https://github.com/novnc/noVNC.git /app/novnc && \
    git clone --depth 1 https://github.com/novnc/websockify /app/novnc/utils/websockify && \
    cp /app/novnc/vnc.html /app/novnc/index.html

# --- KEYBOARD FIX ---
# This 'sed' command injects a large floating Keyboard button into the HTML
RUN sed -i 's|</body>| \
<div id="mobile-keyboard-toggle" style="position: fixed; bottom: 20px; right: 20px; z-index: 9999;"> \
  <button type="button" onclick="document.getElementById('\''noVNC_keyboard_button'\'').click()" \
  style="padding: 15px 20px; font-size: 24px; background: #007bff; color: white; border: none; border-radius: 50px; box-shadow: 0 4px 6px rgba(0,0,0,0.3);"> \
  ⌨️ Keyboard \
  </button> \
</div> \
</body>|' /app/novnc/index.html

# Download and Install Tor Browser
USER toruser
WORKDIR /home/toruser

RUN curl -sLO https://www.torproject.org/dist/torbrowser/14.0.3/tor-browser-linux-x86_64-14.0.3.tar.xz \
    && tar -xf tor-browser-linux-x86_64-14.0.3.tar.xz \
    && rm tor-browser-linux-x86_64-14.0.3.tar.xz

# Copy the start script
COPY --chown=toruser:toruser start.sh /home/toruser/start.sh
RUN chmod +x /home/toruser/start.sh

EXPOSE 8080

CMD ["/home/toruser/start.sh"]
