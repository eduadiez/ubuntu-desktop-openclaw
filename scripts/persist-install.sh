#!/bin/bash
# persist-install.sh — Install a package and make it persistent across container restarts
#
# Usage:
#   sudo persist-install <package-name>           # Install a standard apt package
#   sudo persist-install --repo <repo-setup.sh>   # Run a repo setup script first, then install
#   sudo persist-install --refresh                 # Reinstall all packages from the list
#   sudo persist-install --list                    # Show currently persisted packages
#   sudo persist-install --remove <package-name>   # Remove from persistence list (and uninstall)
#
# Examples:
#   sudo persist-install vlc
#   sudo persist-install gimp inkscape     # multiple packages
#   sudo persist-install brave-browser     # (after adding the repo — see brave example below)

set -e

PERSIST_DIR="/home/desktop/.persist"
PACKAGES_FILE="${PERSIST_DIR}/packages.list"
REPOS_DIR="${PERSIST_DIR}/repos.d"
KEYS_DIR="${PERSIST_DIR}/keys.d"
APT_CACHE_DIR="${PERSIST_DIR}/apt-cache"

mkdir -p "${PERSIST_DIR}" "${REPOS_DIR}" "${KEYS_DIR}" "${APT_CACHE_DIR}"

# Ensure cache symlink
if [ ! -L /var/cache/apt/archives ]; then
    mkdir -p /var/cache/apt
    rm -rf /var/cache/apt/archives
    ln -sf "${APT_CACHE_DIR}" /var/cache/apt/archives
    mkdir -p "${APT_CACHE_DIR}/partial"
fi

# Create packages file if missing
[ -f "${PACKAGES_FILE}" ] || touch "${PACKAGES_FILE}"

add_to_list() {
    local pkg="$1"
    if ! grep -qx "${pkg}" "${PACKAGES_FILE}" 2>/dev/null; then
        echo "${pkg}" >> "${PACKAGES_FILE}"
        echo "[persist] Added '${pkg}' to persistent packages list."
    else
        echo "[persist] '${pkg}' is already in the persistent list."
    fi
}

remove_from_list() {
    local pkg="$1"
    if grep -qx "${pkg}" "${PACKAGES_FILE}" 2>/dev/null; then
        sed -i "/^${pkg}$/d" "${PACKAGES_FILE}"
        echo "[persist] Removed '${pkg}' from persistent packages list."
    else
        echo "[persist] '${pkg}' was not in the persistent list."
    fi
}

save_repos() {
    # Save any new repo files and GPG keys for persistence
    echo "[persist] Saving repository configuration..."
    cp -f /etc/apt/sources.list.d/*.list "${REPOS_DIR}/" 2>/dev/null || true
    cp -f /etc/apt/sources.list.d/*.sources "${REPOS_DIR}/" 2>/dev/null || true
    cp -f /etc/apt/keyrings/*.gpg "${KEYS_DIR}/" 2>/dev/null || true
    cp -f /usr/share/keyrings/*.gpg "${KEYS_DIR}/" 2>/dev/null || true
}

case "${1}" in
    --refresh)
        echo "[persist] Refreshing all persistent packages..."
        packages=$(grep -v '^\s*#' "${PACKAGES_FILE}" | grep -v '^\s*$' | tr '\n' ' ')
        if [ -n "${packages}" ]; then
            apt-get update -qq
            apt-get install -y ${packages}
            echo "[persist] All packages reinstalled."
        else
            echo "[persist] No packages in the list."
        fi
        ;;
    --list)
        echo "=== Persistent Packages ==="
        if [ -f "${PACKAGES_FILE}" ]; then
            grep -v '^\s*#' "${PACKAGES_FILE}" | grep -v '^\s*$' || echo "(none)"
        else
            echo "(none)"
        fi
        ;;
    --remove)
        shift
        for pkg in "$@"; do
            apt-get remove -y "${pkg}" 2>/dev/null || true
            remove_from_list "${pkg}"
        done
        ;;
    --help|-h)
        echo "Usage:"
        echo "  sudo persist-install <package> [package2 ...]   Install & persist packages"
        echo "  sudo persist-install --refresh                  Reinstall all persisted packages"
        echo "  sudo persist-install --list                     List persisted packages"
        echo "  sudo persist-install --remove <package>         Remove from persistent list"
        echo ""
        echo "For third-party repos (e.g., Brave, VS Code), add the repo first,"
        echo "then run persist-install. Repos & keys are saved automatically."
        echo ""
        echo "Example — Installing Brave:"
        echo "  curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg \\"
        echo "    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
        echo '  echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \'
        echo "    > /etc/apt/sources.list.d/brave-browser-release.list"
        echo "  sudo persist-install brave-browser"
        ;;
    *)
        if [ $# -eq 0 ]; then
            echo "No packages specified. Use --help for usage."
            exit 1
        fi

        apt-get update -qq
        apt-get install -y "$@"

        # Add each package to the persistent list
        for pkg in "$@"; do
            add_to_list "${pkg}"
        done

        # Save repos/keys in case a new third-party repo was added
        save_repos

        echo ""
        echo "[persist] Done! These packages will be reinstalled automatically on container restart."
        ;;
esac
