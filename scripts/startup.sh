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
echo "  MATE Desktop + noVNC"
echo "============================================"
echo "  VNC Port:    ${VNC_PORT}"
echo "  noVNC Port:  ${NOVNC_PORT}"
echo "  Resolution:  ${VNC_RESOLUTION}"
echo "  User:        ${USER}"
echo "============================================"

# ----- Ensure home directory is properly initialized -----
# When mounting an empty volume, home dir will be empty
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

# Mark shortcuts as trusted (so MATE doesn't ask "do you trust this?")
chmod +x "${DESKTOP_DIR}"/*.desktop
# For MATE/Caja to trust them, set the metadata
for f in "${DESKTOP_DIR}"/*.desktop; do
    dbus-launch gio set "$f" metadata::trusted true 2>/dev/null || true
done

# Ensure correct ownership (skip .persist/apt-cache for speed)
find "${HOME}" -maxdepth 1 -not -name ".persist" -exec chown ${USER}:${USER} {} + 2>/dev/null || true
chown -R ${USER}:${USER} "${DESKTOP_DIR}" 2>/dev/null || true
chown ${USER}:${USER} "${HOME}" 2>/dev/null || true

# ----- Initialize persistence directories -----
mkdir -p "${PERSIST_DIR}" "${REPOS_DIR}" "${KEYS_DIR}" "${SCRIPTS_DIR}" "${APT_CACHE_DIR}"

if [ ! -f "${PACKAGES_FILE}" ]; then
    cat > "${PACKAGES_FILE}" <<'PKGEOF'
# Persistent packages - one per line
# Lines starting with # are comments
# 
# Examples:
#   brave-browser
#   vlc
#   gimp
#   code
#
# After editing, restart the container or run:
#   sudo /opt/persist-install.sh
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

# ----- Use persistent APT cache for faster reinstalls -----
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

# ----- Setup Node.js if this is the openclaw variant -----
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
    # Manual password encoding fallback (tigervnc DES format)
    echo "WARNING: vncpasswd not found, generating password file manually..."
    python3 -c "
import struct, hashlib
pw = '${VNC_PASSWORD}'[:8].ljust(8, '\x00')
# VNC uses a DES key with reversed bits per byte
key = bytes([int('{:08b}'.format(b)[::-1], 2) for b in pw.encode('latin-1')])
from Crypto.Cipher import DES
cipher = DES.new(key, DES.MODE_ECB)
challenge = b'\x00' * 8
encrypted = cipher.encrypt(challenge)
with open('${VNC_DIR}/passwd', 'wb') as f:
    f.write(encrypted)
" 2>/dev/null || {
        # Simplest fallback: use tigervnc's --SecurityTypes None
        echo "WARNING: Could not set VNC password. Using no authentication."
        VNC_SECURITY="None"
    }
fi
chmod 600 "${VNC_DIR}/passwd"

# Copy xstartup
cp /opt/xstartup "${VNC_DIR}/xstartup"
chmod +x "${VNC_DIR}/xstartup"

chown -R ${USER}:${USER} "${VNC_DIR}"

# ----- Cleanup stale locks -----
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# ----- Start VNC server as user -----
VNC_SECURITY=${VNC_SECURITY:-VncAuth}
VNCSERVER_BIN=$(command -v vncserver || find /usr -name vncserver -type f 2>/dev/null | head -1 || echo "vncserver")

echo "Starting VNC server on :0 (port ${VNC_PORT}) [security: ${VNC_SECURITY}]..."
su - ${USER} -c "${VNCSERVER_BIN} :0 \
    -geometry ${VNC_RESOLUTION} \
    -depth ${VNC_COL_DEPTH} \
    -localhost no \
    -SecurityTypes ${VNC_SECURITY} \
    -xstartup ${VNC_DIR}/xstartup \
    --I-KNOW-THIS-IS-INSECURE"

# Wait for VNC to be ready
echo "Waiting for VNC server..."
for i in $(seq 1 30); do
    if [ -e /tmp/.X11-unix/X0 ]; then
        echo "VNC server is ready."
        break
    fi
    sleep 1
done

if [ ! -e /tmp/.X11-unix/X0 ]; then
    echo "ERROR: VNC server failed to start. Check logs:"
    cat "${VNC_DIR}"/*.log 2>/dev/null || true
    exit 1
fi

echo ""
echo "============================================"
echo "  Ready! Connect via browser:"
echo "  http://<host-ip>:${NOVNC_PORT}"
echo "  VNC password: ${VNC_PASSWORD}"
echo "============================================"
echo ""

# ----- Start noVNC in foreground (keeps container alive) -----
echo "Starting noVNC on port ${NOVNC_PORT}..."
exec websockify \
    --web /usr/share/novnc \
    ${NOVNC_PORT} \
    localhost:${VNC_PORT}
