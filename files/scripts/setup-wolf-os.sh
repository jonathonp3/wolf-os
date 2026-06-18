#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS Unified Assembly..."

# --- MISSION 1: HARDWARE OPTIMIZATION ---
echo "📦 Enabling RPM Fusion and installing hardware drivers..."
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm \
               https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
dnf makecache
dnf install -y mesa-va-drivers-freeworld

# --- MISSION 2: DECLARATIVE IDENTITY (Nix-style Users/Groups) ---
echo "👤 Generating Identity Blueprints..."
mkdir -p /usr/lib/sysusers.d
cat <<EOF > /usr/lib/sysusers.d/wolf-os.conf
g piavpn - -
g piahnsd - -
m jonathon libvirt
m jonathon piavpn
EOF

# --- MISSION 3: DECLARATIVE WIRING (Self-Healing Links) ---
echo "🔗 Generating Filesystem Blueprints..."
mkdir -p /usr/lib/tmpfiles.d
cat <<EOF > /usr/lib/tmpfiles.d/piavpn.conf
# 1. Create the persistent data folders
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -

# 2. THE COMPLETE BLUEPRINT: Bridge /var back to the immutable /usr store
L /var/opt/piavpn/bin - - - - /usr/lib/pia-engine/opt/piavpn/bin
L /var/opt/piavpn/lib - - - - /usr/lib/pia-engine/opt/piavpn/lib
L /var/opt/piavpn/etc - - - - /usr/lib/pia-engine/opt/piavpn/etc
L /var/opt/piavpn/plugins - - - - /usr/lib/pia-engine/opt/piavpn/plugins
L /var/opt/piavpn/qml - - - - /usr/lib/pia-engine/opt/piavpn/qml
L /var/opt/piavpn/share - - - - /usr/lib/pia-engine/opt/piavpn/share
L /var/opt/piavpn/var - - - - /var/lib/piavpn

# 3. SELINUX BOOT-TIME LABELS
Z /usr/lib/pia-engine - - - - system_u:object_r:bin_t:s0
Z /var/lib/piavpn - - - - system_u:object_r:var_lib_t:s0
EOF

# --- MISSION 4: EXTRACTION & STORE ---
echo "📦 Extracting PIA Engine into the Store..."
mkdir -p /usr/lib/pia-engine
# BlueBuild mounts repo assets at /tmp/files/
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/lib/pia-engine/

# --- MISSION 5: SYSTEM INTEGRATION & AUTO-START FIX ---
echo "⚙️ Wiring System Services and Security..."
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d /usr/share/applications /usr/share/pixmaps

# Copy from Store to Factory paths
cp /usr/lib/pia-engine/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/lib/pia-engine/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf
cp /usr/lib/pia-engine/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/lib/pia-engine/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png

# THE AUTO-START FIX: Ensure the daemon waits for the wiring links to exist
sed -i '/\[Unit\]/a After=systemd-tmpfiles-setup.service' /usr/lib/systemd/system/piavpn.service
sed -i '/\[Unit\]/a Requires=systemd-tmpfiles-setup.service' /usr/lib/systemd/system/piavpn.service

# THE SECURITY FIX: Point to real path and inject Unconfined context
sed -i 's|ExecStart=/opt/piavpn/bin/pia-daemon|ExecStart=/usr/lib/pia-engine/opt/piavpn/bin/pia-daemon|' /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# Apply DNS Capability
setcap 'cap_net_bind_service=+ep' /usr/lib/pia-engine/opt/piavpn/bin/pia-unbound || true

# --- MISSION 6: FINALIZE ---
echo "🔄 Enabling System Services..."
systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Custom Assembly Complete!"

