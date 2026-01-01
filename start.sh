#!/bin/bash

# Port set by Render or default to 8080
PORT=${PORT:-8080}
PASS="Clownop"

# 1. Create VNC password
mkdir -p /home/toruser/.vnc
x11vnc -storepasswd "$PASS" /home/toruser/.vnc/passwd

echo "Starting Tor Browser 11.5.0 on Port $PORT..."

# 2. Start Virtual Screen (Xvfb)
# -ac disables access control for internal services
Xvfb :99 -screen 0 ${SCREEN_RESOLUTION}x16 -ac &
sleep 2

# 3. Start Window Manager (Openbox)
DISPLAY=:99 openbox-session &

# 4. Start Tor Browser
# We use --detach so the script can continue to the VNC server
cd /home/toruser/tor-browser-linux
./start-tor-browser.desktop --detach &

# 5. Start VNC Server with password
x11vnc -display :99 -forever -shared -bg -rfbport 5900 -rfbauth /home/toruser/.vnc/passwd

# 6. Start noVNC Bridge
echo "Web VNC is now starting. Access via Render URL."
/app/novnc/utils/novnc_proxy --vnc localhost:5900 --listen $PORT --web /app/novnc
