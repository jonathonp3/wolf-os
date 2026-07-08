##!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
REMOTE_URL="https://www.privateinternetaccess.com/download/linux-vpn"
PIA_VAR_DIR="/var/opt/piavpn"
VERSION_FILE="$PIA_VAR_DIR/share/version.txt"
BACKUP_NAME="pia-repackage.tar.gz"
BACKUP_PATH="$HOME/$BACKUP_NAME"
CONTAINER_NAME="pia-factory"

# Locked Group IDs
GID_PIAVPN=955
GID_PIAHNSD=954

echo "🚀 Sirius-OS PIA VPN Provisioner starting..."

# --- 1. DISCOVERY ---
echo "🔍 Checking for latest PIA version online..."
LATEST_URL=$(curl -sL -A "Mozilla/5.0" $REMOTE_URL | \
             grep -oE 'https://installers\.privateinternetaccess\.com/download/pia-linux-[0-9.]+-[0-9]+\.run' | \
             head -n 1)

if [ -z "$LATEST_URL" ]; then
    echo "❌ Error: Could not find download URL."
    exit 1
fi

# Clean version for comparison (e.g., 3.7.2-08420)
LATEST_VER=$(echo "$LATEST_URL" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+')

# --- 2. VERSION CHECK ---
if [[ -f "$VERSION_FILE" ]]; then
    # Extract just the version pattern from the messy local file
    CURRENT_VER=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' "$VERSION_FILE" | head -n 1 || echo "unknown")
    echo "📊 Status: Local ($CURRENT_VER) | Online ($LATEST_VER)"
    
    if [[ "$CURRENT_VER" == "$LATEST_VER" ]]; then
        echo "✅ Wolf-OS is already running the latest version. Skipping install."
        exit 0
    fi
    echo "🔄 New version detected! Preparing update..."
else
    echo "🆕 No existing installation found. Starting first-time setup..."
fi

# --- 3. THE FACTORY ---
echo "🏗️ Building extraction factory (Distrobox)..."
rm -f "$BACKUP_PATH"
distrobox rm -f "$CONTAINER_NAME" --yes >/dev/null 2>&1 || :
distrobox create --name "$CONTAINER_NAME" --image fedora:latest --yes >/dev/null

distrobox enter "$CONTAINER_NAME" -- bash -c "
  set -euo pipefail
  sudo dnf install -y wget tar systemd NetworkManager procps-ng libnsl >/dev/null
  wget -q -O /tmp/pia.run '$LATEST_URL'
  chmod +x /tmp/pia.run
  /tmp/pia.run --quiet || true
  
  if [ -d /opt/piavpn ]; then
    sudo tar -czf ~/$BACKUP_NAME /opt/piavpn /etc/systemd/system/piavpn.service /etc/NetworkManager/conf.d/wgpia.conf
    sudo chown $(id -u):$(id -g) ~/$BACKUP_NAME
  else
    exit 1
  fi
"
distrobox rm -f "$CONTAINER_NAME" --yes >/dev/null

# --- 4. DEPLOYMENT (Credential-Safe) ---
echo "🚚 Deploying files to Wolf-OS persistent store..."
sudo mkdir -p "$PIA_VAR_DIR"
sudo find "$PIA_VAR_DIR" -mindepth 1 -maxdepth 1 ! -name etc -exec rm -rf {} +

# Extract binaries and config
sudo tar -xpzf "$BACKUP_PATH" -C / --no-same-owner --wildcards 'etc/*'
sudo tar -xpzf "$BACKUP_PATH" -C "$PIA_VAR_DIR" --no-same-owner --strip-components=2 --exclude='opt/piavpn/etc' opt/piavpn

# --- 5. INTEGRATION ---
echo "🔧 Configuring system settings..."
sudo ln -sf /var/opt/piavpn/bin/piactl /usr/local/bin/piactl
sudo ln -sf /var/opt/piavpn/bin/pia-daemon /usr/local/bin/pia-daemon
sudo ln -sf /var/opt/piavpn/bin/pia-client /usr/local/bin/pia-client

if [[ -f /etc/systemd/system/piavpn.service ]]; then
    sudo sed -i -e 's|/opt/piavpn|/var/opt/piavpn|g' /etc/systemd/system/piavpn.service
fi

sudo chown -R root:root "$PIA_VAR_DIR"
sudo groupadd -r piavpn || true
sudo chgrp -R "$GID_PIAVPN" "$PIA_VAR_DIR/etc" 2>/dev/null || :
sudo chmod 755 "$PIA_VAR_DIR/bin/"*
sudo setcap 'cap_net_bind_service=+ep' "$PIA_VAR_DIR/bin/pia-unbound" || true

sudo systemctl daemon-reload
sudo

# --- 3. THE FACTORY ---
echo "🏗️ Building extraction factory (Distrobox)..."
rm -f "$BACKUP_PATH"
distrobox rm -f "$CONTAINER_NAME" --yes >/dev/null 2>&1 || :
distrobox create --name "$CONTAINER_NAME" --image fedora:latest --yes >/dev/null

distrobox enter "$CONTAINER_NAME" -- bash -c "
  set -euo pipefail
  sudo dnf install -y wget tar systemd NetworkManager procps-ng libnsl >/dev/null
  wget -q -O /tmp/pia.run '$LATEST_URL'
  chmod +x /tmp/pia.run
  /tmp/pia.run --quiet || true
  
  if [ -d /opt/piavpn ]; then
    sudo tar -czf ~/$BACKUP_NAME /opt/piavpn /etc/systemd/system/piavpn.service /etc/NetworkManager/conf.d/wgpia.conf
    sudo chown $(id -u):$(id -g) ~/$BACKUP_NAME
  else
    exit 1
  fi
"
distrobox rm -f "$CONTAINER_NAME" --yes >/dev/null

# --- 4. DEPLOYMENT (Credential-Safe) ---
echo "🚚 Deploying files to Wolf-OS persistent store..."

# Ensure target directory exists
sudo mkdir -p "$PIA_VAR_DIR"

# A. Extract system configs directly to /etc (always safe to overwrite)
sudo tar -xpzf "$BACKUP_PATH" -C / --no-same-owner --wildcards 'etc/*'

# B. Extract binaries while PROTECTING the etc folder
# We delete everything EXCEPT the 'etc' folder first
sudo find "$PIA_VAR_DIR" -mindepth 1 -maxdepth 1 ! -name etc -exec rm -rf {} +

# Now extract the contents of the archive
# --exclude='opt/piavpn/etc' ensures we don't overwrite your credentials!
sudo tar -xpzf "$BACKUP_PATH" -C "$PIA_VAR_DIR" --no-same-owner --strip-components=2 \
    --exclude='opt/piavpn/etc' \
    opt/piavpn

# C. If this is a BRAND NEW install (no etc exists), extract ONLY the etc folder
if [ ! -d "$PIA_VAR_DIR/etc" ]; then
    echo "📁 First-time install: extracting default configurations..."
    sudo tar -xpzf "$BACKUP_PATH" -C "$PIA_VAR_DIR" --no-same-owner --strip-components=2 opt/piavpn/etc
fi

# --- 5. INTEGRATION ---
echo "🔧 Configuring system settings..."

# Re-link for Atomic standard
sudo ln -sf /var/opt/piavpn/bin/piactl /usr/local/bin/piactl
sudo ln -sf /var/opt/piavpn/bin/pia-daemon /usr/local/bin/pia-daemon
sudo ln -sf /var/opt/piavpn/bin/pia-client /usr/local/bin/pia-client

# Fix paths in service file
if [[ -f /etc/systemd/system/piavpn.service ]]; then
    sudo sed -i -e 's|/opt/piavpn|/var/opt/piavpn|g' /etc/systemd/system/piavpn.service
fi

# Set Ownership & Permissions (Locked GIDs)
sudo chown -R root:root "$PIA_VAR_DIR"
sudo groupadd -r piavpn || true
# Ensure the etc folder (and credentials) are restricted to the piavpn group
sudo chgrp -R "$GID_PIAVPN" "$PIA_VAR_DIR/etc"
sudo chmod 750 "$PIA_VAR_DIR/etc"
sudo chmod 640 "$PIA_VAR_DIR/etc/"*.json 2>/dev/null || :
sudo chmod 755 "$PIA_VAR_DIR/bin/"*
sudo setcap 'cap_net_bind_service=+ep' "$PIA_VAR_DIR/bin/pia-unbound" || true

# Activation
sudo systemctl daemon-reload
sudo systemctl enable --now piavpn.service

rm -f "$BACKUP_PATH"
echo "✨ PIA VPN Updated to $LATEST_VER (Credentials preserved)."

