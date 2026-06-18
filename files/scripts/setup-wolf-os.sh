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

# 1. Extract into the Store
mkdir -p /usr/lib/pia-engine
tar -xpJf /tmp/pia-backup.tar.xz -C /usr/lib/pia-engine/

# 2. DECLARATIVE BLUEPRINTS (Identity and Wiring)
# We create these directly in /usr/lib so they are ALWAYS in the image
mkdir -p /usr/lib/sysusers.d /usr/lib/tmpfiles.d

cat <<EOF > /usr/lib/sysusers.d/wolf-os.conf
g piavpn - -
g piahnsd - -
m jonathon libvirt
m jonathon piavpn
EOF

cat <<EOF > /usr/lib/tmpfiles.d/piavpn.conf
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -
L /var/opt/piavpn/bin - - - - /usr/lib/pia-engine/opt/piavpn/bin
L /var/opt/piavpn/lib - - - - /usr/lib/pia-engine/opt/piavpn/lib
L /var/opt/piavpn/var - - - - /var/lib/piavpn
EOF

# 3. WIRE SYSTEM FILES (Service and Network)
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/lib/pia-engine/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# 4. INJECT SECURITY CONTEXT
# This allows the daemon to escape the restricted domain
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# 5. UI COMPONENTS
mkdir -p /usr/share/applications /usr/share/pixmaps
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# 6. PERMISSIONS & ENABLE
setcap 'cap_net_bind_service=+ep' /usr/lib/pia-engine/opt/piavpn/bin/pia-unbound || true
systemctl enable libvirtd.service piavpn.service

echo "✅ Wolf-OS Generation Complete!"

