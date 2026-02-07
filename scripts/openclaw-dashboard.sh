#!/bin/bash
# OpenClaw Dashboard Launcher
# This script runs openclaw dashboard and opens it in Brave

# Wait for X server to be ready
sleep 5

# Export display
export DISPLAY=:0

# Wait for gateway to be ready
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://localhost:18789 >/dev/null 2>&1 || netstat -tln | grep -q ':18789'; then
        echo "[openclaw-dashboard] Gateway is ready"
        break
    fi
    echo "[openclaw-dashboard] Waiting for gateway... ($attempt/$max_attempts)"
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "[openclaw-dashboard] Gateway not ready after waiting, exiting"
    exit 1
fi

# Wait a bit more to ensure everything is stable
sleep 3

# Kill any existing Brave processes first
echo "[openclaw-dashboard] Checking for existing Brave processes..."
pkill -u desktop brave-browser 2>/dev/null || true
pkill -u desktop brave 2>/dev/null || true
sleep 2

# Get dashboard URL using openclaw CLI
echo "[openclaw-dashboard] Getting OpenClaw dashboard URL..."
cd /home/desktop

# Set up NVM environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Clean up Brave lock files
rm -f "$HOME/.config/BraveSoftware/Brave-Browser/SingletonLock" 2>/dev/null || true
rm -f "$HOME/.config/BraveSoftware/Brave-Browser/SingletonSocket" 2>/dev/null || true
rm -f "$HOME/.config/BraveSoftware/Brave-Browser/SingletonCookie" 2>/dev/null || true

# Try to get the dashboard URL (run in background to avoid hanging)
openclaw dashboard > /tmp/openclaw-dashboard-cmd.log 2>&1 &
OPENCLAW_PID=$!

# Wait a bit for the URL to be generated
sleep 3

# Get the URL from output
DASHBOARD_OUTPUT=$(cat /tmp/openclaw-dashboard-cmd.log 2>/dev/null || echo "")
DASHBOARD_URL=$(echo "$DASHBOARD_OUTPUT" | grep -o 'http://127.0.0.1:18789[^[:space:]]*' | head -1)

# Keep the openclaw dashboard process running in background
disown $OPENCLAW_PID 2>/dev/null || true

if [ -n "$DASHBOARD_URL" ]; then
    echo "[openclaw-dashboard] Dashboard URL: $DASHBOARD_URL"
    echo "$DASHBOARD_URL" > /tmp/openclaw-dashboard-url.txt

    # Update Brave preferences to set dashboard as startup page
    BRAVE_PREFS="$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences"
    if [ -f "$BRAVE_PREFS" ]; then
        # Backup existing preferences
        cp "$BRAVE_PREFS" "$BRAVE_PREFS.bak" 2>/dev/null || true

        # Use Python to update JSON preferences
        python3 << PYTHONEOF
import json
import sys

try:
    with open('$BRAVE_PREFS', 'r') as f:
        prefs = json.load(f)

    # Set startup URLs
    prefs['session'] = prefs.get('session', {})
    prefs['session']['restore_on_startup'] = 4  # 4 = Open specific URLs
    prefs['session']['startup_urls'] = ['$DASHBOARD_URL']

    with open('$BRAVE_PREFS', 'w') as f:
        json.dump(prefs, f, indent=3)

    print('[openclaw-dashboard] Updated Brave preferences with dashboard URL')
except Exception as e:
    print(f'[openclaw-dashboard] Failed to update preferences: {e}', file=sys.stderr)
PYTHONEOF
    fi

    # Launch Brave binary directly (bypass wrapper script)
    echo "[openclaw-dashboard] Opening Brave..."
    setsid nohup /opt/brave.com/brave/brave --no-sandbox --disable-gpu "$DASHBOARD_URL" > /tmp/brave-launch.log 2>&1 </dev/null &

    #echo "[openclaw-dashboard] Brave launched with OpenClaw Dashboard"
else
    echo "[openclaw-dashboard] Failed to get dashboard URL"
    echo "$DASHBOARD_OUTPUT" > /tmp/openclaw-dashboard-error.log

    # Fallback: open gateway root URL
    echo "[openclaw-dashboard] Opening gateway root as fallback..."
    setsid nohup /opt/brave.com/brave/brave --no-sandbox --disable-gpu "http://127.0.0.1:18789" > /tmp/brave-launch.log 2>&1 </dev/null &
fi