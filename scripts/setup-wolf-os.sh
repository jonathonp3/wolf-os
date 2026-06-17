#!/bin/bash
set -e

echo "🚀 Starting Wolf-OS Post-Install Surgery..."

# 1. Prepare the Nix-style Store
mkdir -p /usr/lib/pia-engine

# 2. Extract the Master Archive (Assuming it is in /tmp/ or copied via recipe)
# Note: BlueBuild will place files from your 'files' folder into the root
tar -xpzf /tmp/pia-backup.tar.gz -C /usr/lib/pia-engine/

# 3. Bake in System Services and Icons
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
mkdir -p /usr/share/applications /usr/share/pixmaps
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# 4. Apply Security Fixes (DNS and SELinux Transition)
setcap 'cap_net_bind_service=+ep' /usr/lib/pia-engine/opt/piavpn/bin/pia-unbound || true
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# 5. Finalize Service State
systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Assembly Complete!"

