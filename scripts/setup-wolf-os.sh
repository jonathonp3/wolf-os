#!/bin/bash
set -e

echo "🚀 Assembling Wolf-OS Components (XZ Optimized)..."

# 1. Prepare the Store and Extract (Note the -xpJf flag for XZ)
mkdir -p /usr/lib/pia-engine
tar -xpJf /tmp/pia-backup.tar.xz -C /usr/lib/pia-engine/

# 2. Wire the Systemd Service
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# 3. Wire the NetworkManager Config
mkdir -p /usr/lib/NetworkManager/conf.d
cp /usr/lib/pia-engine/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# 4. Wire the GUI
mkdir -p /usr/share/applications /usr/share/pixmaps
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# 5. Apply Security Capabilities
setcap 'cap_net_bind_service=+ep' /usr/lib/pia-engine/opt/piavpn/bin/pia-unbound || true

# 6. Enable Services
systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Assembly Complete!"

