#!/bin/bash

# Default port
PORT=${PORT:-8080}

echo "Starting Tor Browser Docker with Mobile Keyboard Support..."
echo "Listening on port $PORT"

# 1. Start Xvfb
Xvfb :99 -screen 0 ${SCREEN_RESOLUTION}x16 &
sleep 2

# 2. Start Openbox
DISPLAY=:99 openbox-session &

# 3. Start Tor Browser
cd /home/toruser/tor-browser
./start-tor-browser.desktop --detach &

# 4. Start x11vnc
x11vnc -display :99 -forever -nopw -shared -bg

# 5. Start noVNC (Websockify)
# Pointing to the GIT version we downloaded to /app/novnc
echo "Starting websockify..."
/app/novnc/utils/novnc_proxy --vnc localhost:5900 --listen $PORT --web /app/novnc
