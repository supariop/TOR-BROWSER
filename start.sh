#!/bin/bash

PORT=${PORT:-8080}

# Start Xvfb (Virtual Screen)
Xvfb :99 -screen 0 ${SCREEN_RESOLUTION}x16 -ac &
sleep 2

# Start Openbox
DISPLAY=:99 openbox-session &

# Start Tor Browser (Lighter launch)
cd /home/toruser/tor-browser-linux
./start-tor-browser.desktop --detach &

# Start x11vnc
x11vnc -display :99 -forever -nopw -shared -bg -rfbport 5900

# Start noVNC proxy
/app/novnc/utils/novnc_proxy --vnc localhost:5900 --listen $PORT --web /app/novnc
