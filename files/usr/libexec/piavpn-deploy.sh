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

# 2. Prepare the persistent directory
mkdir -p "$PIA_VAR_DIR"

# 3. Wipe old binaries/libraries but PROTECT the 'etc' folder (credentials)
if [[ -d "$PIA_VAR_DIR/bin" ]]; then
    echo "🧹 Cleaning up old binaries..."
    find "$PIA_VAR_DIR" -mindepth 1 -maxdepth 1 ! -name etc -exec rm -rf {} +
fi

# 4. Extract new system configurations to /etc (Service file, NM config)
tar -xpzf "$STAGING_TAR" -C / --no-same-owner --wildcards 'etc/*' || true

# 5. Extract binaries into /var/opt/piavpn but exclude the etc folder
tar -xpzf "$STAGING_TAR" -C "$PIA_VAR_DIR" --no-same-owner --strip-components=2 \
    --exclude='opt/piavpn/etc' \
    opt/piavpn || true

# 6. Ensure the etc directory exists (for fresh installs)
if [ ! -d "$PIA_VAR_DIR/etc" ]; then
    mkdir -p "$PIA_VAR_DIR/etc"
fi

# 7. INTEGRATION: Correct paths and permissions
echo "🔧 Configuring system integration..."

# --- THE MISSING PIECE: Binary Symlinks ---
# This ensures 'piactl' and 'pia-client' are in the system PATH
ln -sf /var/opt/piavpn/bin/piactl /usr/local/bin/piactl
ln -sf /var/opt/piavpn/bin/pia-daemon /usr/local/bin/pia-daemon
ln -sf /var/opt/piavpn/bin/pia-client /usr/local/bin/pia-client

# Fix paths in the service file to point to /var/opt instead of /opt
if [[ -f /etc/systemd/system/piavpn.service ]]; then
    sed -i -e 's|/opt/piavpn|/var/opt/piavpn|g' /etc/systemd/system/piavpn.service
fi

# Set Ownership & Permissions (Locked GIDs)
chown -R root:root "$PIA_VAR_DIR"
groupadd -r piavpn || true
chgrp -R "$GID_PIAVPN" "$PIA_VAR_DIR/etc" 2>/dev/null || :
chmod 755 "$PIA_VAR_DIR/bin/"*

# Networking: Grant DNS capabilities to Unbound
setcap 'cap_net_bind_service=+ep' "$PIA_VAR_DIR/bin/pia-unbound" || true

# 8. CLEANUP
rm -f "$STAGING_TAR"

echo "✨ Files deployed. Systemd will now start the VPN."

