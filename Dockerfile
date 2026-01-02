FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    SCREEN_RESOLUTION=800x600 \
    DISPLAY=:99

RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb x11vnc openbox python3-websockify python3-numpy \
    curl git ca-certificates xz-utils libgtk-3-0 \
    libdbus-glib-1-2 libxt6 libx11-xcb1 procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash toruser

RUN mkdir -p /app && \
    git clone --depth 1 https://github.com/novnc/noVNC.git /app/novnc && \
    git clone --depth 1 https://github.com/novnc/websockify /app/novnc/utils/websockify && \
    cp /app/novnc/vnc.html /app/novnc/index.html

USER toruser
WORKDIR /home/toruser
RUN curl -sfL "https://archive.torproject.org/tor-package-archive/torbrowser/11.5/tor-browser-linux64-11.5_en-US.tar.xz" -o tor.tar.xz \
    && tar -xf tor.tar.xz \
    && rm tor.tar.xz \
    && mv tor-browser_en-US tor-browser-linux

# --- THE "ULTRA-LEAN" OPTIMIZATION BLOCK ---
# These settings force the browser to release RAM and limit cache size
RUN echo 'pref("app.update.auto", false);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js && \
    echo 'pref("app.update.enabled", false);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js && \
    echo 'pref("browser.cache.memory.capacity", 16384);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js && \
    echo 'pref("browser.sessionhistory.max_entries", 1);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js && \
    echo 'pref("javascript.options.mem.gc_per_compartment", true);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js && \
    echo 'pref("image.mem.surfacecache.max_size_kb", 4096);' >> /home/toruser/tor-browser-linux/Browser/defaults/pref/autoconfig.js

COPY --chown=toruser:toruser start.sh /home/toruser/start.sh
RUN chmod +x /home/toruser/start.sh

EXPOSE 8080
CMD ["/home/toruser/start.sh"]
