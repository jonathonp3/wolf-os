#!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
STAGING_TAR="/tmp/pia-stage.tar.gz"
PIA_VAR_DIR="/var/opt/piavpn"
GID_PIAVPN=955

# 1. Skip if the Producer service didn't create a new package
if [[ ! -f "$STAGING_TAR" ]]; then
    exit 0
fi

echo "🚚 Root: Deploying VPN update to persistent store..."

# 2. Prepare the persistent directory and UI paths
mkdir -p "$PIA_VAR_DIR"
mkdir -p /usr/local/share/applications
mkdir -p /usr/local/share/pixmaps

# 3. Wipe old binaries/libraries but PROTECT the 'etc' folder (credentials)
if [[ -d "$PIA_VAR_DIR/bin" ]]; then
    echo "🧹 Cleaning up old binaries..."
    find "$PIA_VAR_DIR" -mindepth 1 -maxdepth 1 ! -name etc -exec rm -rf {} +
fi

# 4. Extract system configurations directly to /etc (Service file, NM config)
echo "📦 Extracting system configurations..."
tar -xpzf "$STAGING_TAR" -C / --no-same-owner --wildcards 'etc/*' || true

# 5. Extract UI assets and REDIRECT to /usr/local (Atomic bypass)
echo "🎨 Integrating UI assets (Icon & Menu Entry)..."
# --strip-components=1 turns 'usr/share/pixmaps/...' into 'share/pixmaps/...'
# which lands in /usr/local/share/pixmaps/...
tar -xpzf "$STAGING_TAR" -C /usr/local --no-same-owner --strip-components=1 \
    usr/share/applications/piavpn.desktop \
    usr/share/pixmaps/piavpn.png || true

# 6. Extract binaries into /var/opt/piavpn but exclude the etc folder
echo "📦 Extracting binaries..."
tar -xpzf "$STAGING_TAR" -C "$PIA_VAR_DIR" --no-same-owner --strip-components=2 \
    --exclude='opt/piavpn/etc' \
    opt/piavpn || true

# 7. Ensure the etc directory exists (for fresh installs)
if [ ! -d "$PIA_VAR_DIR/etc" ]; then
    echo "📁 Creating etc directory for credentials..."
    mkdir -p "$PIA_VAR_DIR/etc"
fi

# 8. INTEGRATION: Correct paths and permissions
echo "🔧 Configuring system integration..."

# Re-link binaries to /usr/local/bin (so they are always in the PATH)
ln -sf /var/opt/piavpn/bin/piactl /usr/local/bin/piactl
ln -sf /var/opt/piavpn/bin/pia-daemon /usr/local/bin/pia-daemon
ln -sf /var/opt/piavpn/bin/pia-client /usr/local/bin/pia-client

# Fix paths in the service file to point to /var/opt instead of /opt
if [[ -f /etc/systemd/system/piavpn.service ]]; then
    sed -i -e 's|/opt/piavpn|/var/opt/piavpn|g' /etc/systemd/system/piavpn.service
fi

# Fix the path inside the Desktop Entry to use our new system-wide link
if [[ -f "/usr/local/share/applications/piavpn.desktop" ]]; then
    sed -i 's|Exec=/opt/piavpn/bin/pia-client|Exec=/usr/local/bin/pia-client|g' /usr/local/share/applications/piavpn.desktop
    # Refresh the menu database
    update-desktop-database /usr/local/share/applications || true
fi

# Set Ownership & Permissions (Locked GIDs)
chown -R root:root "$PIA_VAR_DIR"
groupadd -r piavpn || true
chgrp -R "$GID_PIAVPN" "$PIA_VAR_DIR/etc" 2>/dev/null || :
chmod 750 "$PIA_VAR_DIR/etc"
# Only restrict JSON files if they exist
find "$PIA_VAR_DIR/etc" -name "*.json" -exec chmod 640 {} + 2>/dev/null || :
chmod 755 "$PIA_VAR_DIR/bin/"*

# Networking: Grant DNS capabilities to Unbound
setcap 'cap_net_bind_service=+ep' "$PIA_VAR_DIR/bin/pia-unbound" || true

# 9. CLEANUP
rm -f "$STAGING_TAR"

echo "✨ Files deployed. Systemd will now start the VPN."

