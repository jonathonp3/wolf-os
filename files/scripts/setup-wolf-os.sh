#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS Master Assembly (Trusted Path Fix)..."

# --- MISSION 1: HARDWARE & REPOS ---
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm \
               https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
dnf makecache
dnf install -y mesa-va-drivers-freeworld

# --- MISSION 2: IDENTITY ---
mkdir -p /usr/lib/sysusers.d
cat <<EOF > /usr/lib/sysusers.d/wolf-os.conf
g piavpn - -
g piahnsd - -
m jonathon libvirt
m jonathon piavpn
EOF

# --- MISSION 3: THE MASTER WIRING BLUEPRINT ---
mkdir -p /usr/lib/tmpfiles.d
cat <<EOF > /usr/lib/tmpfiles.d/piavpn.conf
# 1. Create the persistent data folders
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -

# 2. THE COMPLETE BLUEPRINT: Every folder the app needs
L /var/opt/piavpn/bin - - - - /usr/bin/pia-vpn-bin
L /var/opt/piavpn/lib - - - - /usr/lib/pia-engine/opt/piavpn/lib
L /var/opt/piavpn/etc - - - - /usr/lib/pia-engine/opt/piavpn/etc
L /var/opt/piavpn/plugins - - - - /usr/lib/pia-engine/opt/piavpn/plugins
L /var/opt/piavpn/qml - - - - /usr/lib/pia-engine/opt/piavpn/qml
L /var/opt/piavpn/share - - - - /usr/lib/pia-engine/opt/piavpn/share
L /var/opt/piavpn/var - - - - /var/lib/piavpn
EOF

# --- MISSION 4: EXTRACTION & STORE ---
mkdir -p /usr/lib/pia-engine
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/lib/pia-engine/

# --- MISSION 5: BLESSED PATH RELOCATION (The SELinux Fix) ---
# We move the binaries to /usr/bin/ subfolder. 
# SELinux trusts /usr/bin/ by default, so 'init_t' can execute these.
mkdir -p /usr/bin/pia-vpn-bin
cp -r /usr/lib/pia-engine/opt/piavpn/bin/* /usr/bin/pia-vpn-bin/
chmod +x /usr/bin/pia-vpn-bin/*

# --- MISSION 6: SYSTEM INTEGRATION ---
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/lib/pia-engine/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# POINT THE SERVICE TO THE BLESSED PATH
sed -i 's|ExecStart=.*|ExecStart=/usr/bin/pia-vpn-bin/pia-daemon|' /usr/lib/systemd/system/piavpn.service
# Inject the Diplomatic Passport
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# UI Components
mkdir -p /usr/share/applications /usr/share/pixmaps
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# Set capabilities on the new path
setcap 'cap_net_bind_service=+ep' /usr/bin/pia-vpn-bin/pia-unbound || true

# --- MISSION 7: FINALIZE ---
systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Assembly Complete! SELinux issues bypassed via /usr/bin relocation."

