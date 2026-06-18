#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS Master Assembly (SELinux Victory Version)..."

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

# --- MISSION 3: THE MASTER WIRING & SECURITY BLUEPRINT ---
mkdir -p /usr/lib/tmpfiles.d
cat <<EOF > /usr/lib/tmpfiles.d/piavpn.conf
# 1. Folders
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -

# 2. Links
L /var/opt/piavpn/bin - - - - /usr/lib/pia-engine/opt/piavpn/bin
L /var/opt/piavpn/lib - - - - /usr/lib/pia-engine/opt/piavpn/lib
L /var/opt/piavpn/etc - - - - /usr/lib/pia-engine/opt/piavpn/etc
L /var/opt/piavpn/plugins - - - - /usr/lib/pia-engine/opt/piavpn/plugins
L /var/opt/piavpn/qml - - - - /usr/lib/pia-engine/opt/piavpn/qml
L /var/opt/piavpn/share - - - - /usr/lib/pia-engine/opt/piavpn/share
L /var/opt/piavpn/var - - - - /var/lib/piavpn

# 3. SELINUX VICTORY (The 'Z' Flag)
# This forces the OS to label the binaries as 'unconfined_exec_t' on boot.
# This allows systemd to execute them even in Enforcing mode.
Z /usr/lib/pia-engine/opt/piavpn/bin - - - - system_u:object_r:unconfined_exec_t:s0
Z /var/lib/piavpn - - - - system_u:object_r:var_lib_t:s0
EOF

# --- MISSION 4: EXTRACTION ---
mkdir -p /usr/lib/pia-engine
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/lib/pia-engine/

# --- MISSION 5: SYSTEM INTEGRATION ---
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/lib/pia-engine/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# Fix the service file to use the physical path and the security context
sed -i 's|ExecStart=/opt/piavpn/bin/pia-daemon|ExecStart=/usr/lib/pia-engine/opt/piavpn/bin/pia-daemon|' /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# UI Components
mkdir -p /usr/share/applications /usr/share/pixmaps
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# --- MISSION 6: PERMISSIONS & FINALIZE ---
setcap 'cap_net_bind_service=+ep' /usr/lib/pia-engine/opt/piavpn/bin/pia-unbound || true
# Replicate the ID 1000 ownership for the GUI
chown 1000:0 /usr/lib/pia-engine/opt/piavpn/bin/pia-client
chown 1000:0 /usr/lib/pia-engine/opt/piavpn/bin/piactl

systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Build Complete! Security Labels set for Boot-time realization."

