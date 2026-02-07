#!/bin/bash
set -e

USER=${USER:-desktop}
HOME=/home/${USER}
VNC_PORT=${VNC_PORT:-5900}
NOVNC_PORT=${NOVNC_PORT:-6080}
VNC_RESOLUTION=${VNC_RESOLUTION:-1920x1080}
VNC_COL_DEPTH=${VNC_COL_DEPTH:-24}
VNC_PASSWORD=${VNC_PASSWORD:-dappnode}

PERSIST_DIR="${HOME}/.persist"
PACKAGES_FILE="${PERSIST_DIR}/packages.list"
REPOS_DIR="${PERSIST_DIR}/repos.d"
KEYS_DIR="${PERSIST_DIR}/keys.d"
SCRIPTS_DIR="${PERSIST_DIR}/scripts.d"
APT_CACHE_DIR="${PERSIST_DIR}/apt-cache"
INSTALL_LOG="${PERSIST_DIR}/install.log"

echo "============================================"
echo "  MATE Desktop + noVNC + OpenClaw Gateway"
echo "============================================"
echo "  VNC Port:    ${VNC_PORT}"
echo "  noVNC Port:  ${NOVNC_PORT}"
echo "  Gateway Port: 18789"
echo "  Resolution:  ${VNC_RESOLUTION}"
echo "  User:        ${USER}"
echo "============================================"

# ----- Ensure home directory is properly initialized -----
if [ ! -f "${HOME}/.bashrc" ]; then
    echo "Initializing home directory for ${USER}..."
    cp -rT /etc/skel "${HOME}" 2>/dev/null || true
fi

# ----- Create desktop shortcuts -----
DESKTOP_DIR="${HOME}/Desktop"
mkdir -p "${DESKTOP_DIR}"

# Brave Browser shortcut
cat > "${DESKTOP_DIR}/brave-browser.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Brave Browser
Comment=Browse the web with Brave
Exec=brave-browser --no-sandbox --disable-gpu
Icon=brave-browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF

# MATE Terminal shortcut
cat > "${DESKTOP_DIR}/mate-terminal.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Open a terminal
Exec=mate-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

# Mark shortcuts as trusted
chmod +x "${DESKTOP_DIR}"/*.desktop
for f in "${DESKTOP_DIR}"/*.desktop; do
    dbus-launch gio set "$f" metadata::trusted true 2>/dev/null || true
done

# Create README.txt on desktop
cat > "${DESKTOP_DIR}/README.txt" <<'EOF'
OpenClaw Development Environment
=================================

Getting Started:
----------------

1. Configure OpenClaw (first time only):

   Open Terminal and run:
   $ openclaw onboard

   This will configure OpenClaw.

2. Access OpenClaw Dashboard:

   Open Brave Browser

3. OpenClaw Gateway:

   The gateway is always running in the background.
   Port: 18789
   Logs: sudo tail -f /var/log/supervisor/openclaw-gateway.log

4. Development Tools:

   - Node.js (latest)
   - npm, yarn, pnpm
   - TypeScript, nodemon, ts-node
   - NVM (Node Version Manager)

For more information, visit: https://docs.openclaw.ai
EOF

chown ${USER}:${USER} "${DESKTOP_DIR}/README.txt"

# Create autostart entry to open README on desktop startup
AUTOSTART_DIR="${HOME}/.config/autostart"
mkdir -p "${AUTOSTART_DIR}"

cat > "${AUTOSTART_DIR}/open-readme.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Open README
Comment=Open README.txt on desktop startup
Exec=pluma /home/desktop/Desktop/README.txt
Terminal=false
NoDisplay=true
StartupNotify=false
X-GNOME-Autostart-enabled=true
X-MATE-Autostart-enabled=true
X-MATE-Autostart-Delay=12
EOF

chmod +x "${AUTOSTART_DIR}/open-readme.desktop"

# ----- Setup OpenClaw Dashboard Auto-launch (No Desktop Shortcut) -----
AUTOSTART_DIR="${HOME}/.config/autostart"
mkdir -p "${AUTOSTART_DIR}"

# Remove desktop shortcut if it exists (not needed)
rm -f "${DESKTOP_DIR}/openclaw-dashboard.desktop" 2>/dev/null || true

# Copy dashboard launcher script
cp /opt/openclaw-dashboard.sh "${HOME}/.openclaw-dashboard.sh" 2>/dev/null || true
chmod +x "${HOME}/.openclaw-dashboard.sh"

# Create autostart entry (auto-launch on desktop startup)
cat > "${AUTOSTART_DIR}/openclaw-dashboard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=OpenClaw Dashboard
Comment=Launch OpenClaw Dashboard in Brave
Exec=sh -c 'nohup /home/desktop/.openclaw-dashboard.sh > /tmp/openclaw-dashboard-autostart.log 2>&1 &'
Terminal=false
Hidden=false
NoDisplay=true
StartupNotify=false
X-GNOME-Autostart-enabled=true
X-MATE-Autostart-enabled=true
X-MATE-Autostart-Delay=5
EOF

chmod +x "${AUTOSTART_DIR}/openclaw-dashboard.desktop"

# ----- Configure Brave Browser -----
# Set Brave to restore last session on startup
BRAVE_PREFS_DIR="${HOME}/.config/BraveSoftware/Brave-Browser/Default"
mkdir -p "${BRAVE_PREFS_DIR}"

# Create or update Brave preferences
if [ ! -f "${BRAVE_PREFS_DIR}/Preferences" ]; then
    cat > "${BRAVE_PREFS_DIR}/Preferences" <<'BRAVEEOF'
{
   "brave": {
      "new_tab_page": {
         "show_background_image": true
      }
   },
   "session": {
      "restore_on_startup": 1
   },
   "browser": {
      "check_default_browser": false,
      "show_home_button": true
   }
}
BRAVEEOF
fi

# Ensure correct ownership
find "${HOME}" -maxdepth 1 -not -name ".persist" -exec chown ${USER}:${USER} {} + 2>/dev/null || true
chown -R ${USER}:${USER} "${DESKTOP_DIR}" 2>/dev/null || true
chown -R ${USER}:${USER} "${HOME}/.local" 2>/dev/null || true
chown -R ${USER}:${USER} "${HOME}/.config" 2>/dev/null || true
chown ${USER}:${USER} "${HOME}" 2>/dev/null || true

# Clean up stale Brave lock files
rm -f "${HOME}/.config/BraveSoftware/Brave-Browser/SingletonLock" 2>/dev/null || true
rm -f "${HOME}/.config/BraveSoftware/Brave-Browser/SingletonSocket" 2>/dev/null || true
rm -f "${HOME}/.config/BraveSoftware/Brave-Browser/SingletonCookie" 2>/dev/null || true

# ----- Initialize persistence directories -----
mkdir -p "${PERSIST_DIR}" "${REPOS_DIR}" "${KEYS_DIR}" "${SCRIPTS_DIR}" "${APT_CACHE_DIR}"

if [ ! -f "${PACKAGES_FILE}" ]; then
    cat > "${PACKAGES_FILE}" <<'PKGEOF'
# Persistent packages - one per line
# Lines starting with # are comments
PKGEOF
fi

# ----- Restore APT repos & GPG keys -----
if [ -d "${REPOS_DIR}" ] && [ "$(ls -A ${REPOS_DIR} 2>/dev/null)" ]; then
    echo "[persist] Restoring APT repositories..."
    cp -f "${REPOS_DIR}"/*.list /etc/apt/sources.list.d/ 2>/dev/null || true
    cp -f "${REPOS_DIR}"/*.sources /etc/apt/sources.list.d/ 2>/dev/null || true
fi

if [ -d "${KEYS_DIR}" ] && [ "$(ls -A ${KEYS_DIR} 2>/dev/null)" ]; then
    echo "[persist] Restoring GPG keys..."
    mkdir -p /etc/apt/keyrings /usr/share/keyrings
    cp -f "${KEYS_DIR}"/*.gpg /etc/apt/keyrings/ 2>/dev/null || true
    cp -f "${KEYS_DIR}"/*.gpg /usr/share/keyrings/ 2>/dev/null || true
fi

# ----- Use persistent APT cache -----
mkdir -p /var/cache/apt
rm -rf /var/cache/apt/archives
ln -sf "${APT_CACHE_DIR}" /var/cache/apt/archives
mkdir -p "${APT_CACHE_DIR}/partial"

# ----- Install persistent packages -----
install_persistent_packages() {
    local packages=""

    if [ -f "${PACKAGES_FILE}" ]; then
        packages=$(grep -v '^\s*#' "${PACKAGES_FILE}" | grep -v '^\s*$' | tr '\n' ' ')
    fi

    if [ -n "${packages}" ]; then
        echo "[persist] Updating package lists..."
        apt-get update -qq 2>&1 | tee -a "${INSTALL_LOG}"

        echo "[persist] Installing packages: ${packages}"
        apt-get install -y --no-install-recommends ${packages} 2>&1 | tee -a "${INSTALL_LOG}"

        echo "[persist] Package installation complete."
    else
        echo "[persist] No persistent packages to install."
    fi
}

# ----- Run custom startup scripts -----
run_custom_scripts() {
    if [ -d "${SCRIPTS_DIR}" ] && [ "$(ls -A ${SCRIPTS_DIR}/*.sh 2>/dev/null)" ]; then
        echo "[persist] Running custom startup scripts..."
        for script in "${SCRIPTS_DIR}"/*.sh; do
            if [ -x "$script" ]; then
                echo "[persist] Running: $(basename $script)"
                bash "$script" 2>&1 | tee -a "${INSTALL_LOG}"
            fi
        done
    fi
}

install_persistent_packages
run_custom_scripts

# ----- Setup Node.js if needed -----
if [ -x /usr/local/bin/setup-nodejs.sh ]; then
    /usr/local/bin/setup-nodejs.sh
fi

# ----- Setup VNC -----
VNC_DIR="${HOME}/.vnc"
mkdir -p "${VNC_DIR}"

# Set VNC password
VNCPASSWD_BIN=$(command -v vncpasswd || find /usr -name vncpasswd -type f 2>/dev/null | head -1)
if [ -n "${VNCPASSWD_BIN}" ]; then
    echo "${VNC_PASSWORD}" | "${VNCPASSWD_BIN}" -f > "${VNC_DIR}/passwd"
else
    echo "WARNING: vncpasswd not found, using no authentication..."
    VNC_SECURITY="None"
fi
chmod 600 "${VNC_DIR}/passwd"

# Copy xstartup
cp /opt/xstartup "${VNC_DIR}/xstartup"
chmod +x "${VNC_DIR}/xstartup"

chown -R ${USER}:${USER} "${VNC_DIR}"

# ----- Cleanup stale locks -----
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# ----- Export environment variables for supervisord -----
export VNC_RESOLUTION VNC_COL_DEPTH VNC_PORT NOVNC_PORT
export VNC_SECURITY=${VNC_SECURITY:-VncAuth}

# Create log directory for supervisor
mkdir -p /var/log/supervisor

echo ""
echo "============================================"
echo "  Starting services with Supervisor..."
echo "============================================"
echo "  VNC Server (port ${VNC_PORT})"
echo "  noVNC (port ${NOVNC_PORT})"
echo "  OpenClaw Gateway (port 18789)"
echo "============================================"
echo ""
echo "Access via browser:"
echo "  http://<host-ip>:${NOVNC_PORT}"
echo "  VNC password: ${VNC_PASSWORD}"
echo ""

# ----- Start supervisord (keeps container alive) -----
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.openclaw.conf