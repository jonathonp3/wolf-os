#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS Custom Assembly..."

# 1. INSTALL RPM FUSION AND FREEWORLD DRIVERS (The Robust Way)
echo "📦 Enabling RPM Fusion and installing hardware drivers..."
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm \
               https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

# Refresh metadata to see the new packages
dnf makecache

# Install the drivers that were failing before
dnf install -y mesa-va-drivers-freeworld

# 2. PREPARE THE STORE AND EXTRACT PIA
mkdir -p /usr/lib/pia-engine
# Note: BlueBuild mounts your 'files' folder at /tmp/files
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/lib/pia-engine/

# 3. WIRE SYSTEMD SERVICE
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# 4. WIRE NETWORKMANAGER & GUI
mkdir -p /usr/lib/NetworkManager/conf.d
cp /usr/lib/pia-engine/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf
mkdir -p /usr/share/applications /usr/share/pixmaps
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# 5. SECURITY & PERMISSIONS
setcap 'cap_net_bind_service=+ep' /usr/lib/pia-engine/opt/piavpn/bin/pia-unbound || true
# Ensure correct ownership for the GUI (ID 1000)
chown 1000:0 /usr/lib/pia-engine/opt/piavpn/bin/pia-client
chown 1000:0 /usr/lib/pia-engine/opt/piavpn/bin/piactl

# 6. ENABLE SERVICES
systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Assembly Complete!"

