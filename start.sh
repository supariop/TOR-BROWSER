#!/bin/bash

PORT=${PORT:-8080}
PASS="Clownop"

# 1. Setup VNC Password
mkdir -p /home/toruser/.vnc
x11vnc -storepasswd "$PASS" /home/toruser/.vnc/passwd

# 2. Start Xvfb with lower bit depth (16-bit) to save RAM
Xvfb :99 -screen 0 ${SCREEN_RESOLUTION}x16 -ac +extension RANDR &
sleep 2

# 3. Start Window Manager
DISPLAY=:99 openbox-session &
sleep 1

# 4. Start Tor Browser with "No Remote" to keep it in one process
cd /home/toruser/tor-browser-linux
DISPLAY=:99 ./start-tor-browser.desktop --detach --no-remote &

# 5. Start VNC Server with high-performance flags
# -ncache 10 helps with the laggy feeling on mobile
x11vnc -display :99 -forever -shared -bg -rfbport 5900 -rfbauth /home/toruser/.vnc/passwd -ncache 10 -speed 5

# 6. Start noVNC
/app/novnc/utils/novnc_proxy --vnc localhost:5900 --listen $PORT --web /app/novnc
