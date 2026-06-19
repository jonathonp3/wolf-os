#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS Master Assembly..."

# --- MISSION 1: HARDWARE & LIBS ---
dnf install -y libnsl libxcrypt-compat nss-tools xterm libXaw libutempter \
               mkfontscale xorg-x11-fonts-misc libxkbcommon-x11 mesa-va-drivers-freeworld
dnf makecache

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
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -
L /var/opt/piavpn/bin - - - - /usr/libexec/piavpn/opt/piavpn/bin
L /var/opt/piavpn/lib - - - - /usr/libexec/piavpn/opt/piavpn/lib
L /var/opt/piavpn/etc - - - - /usr/libexec/piavpn/opt/piavpn/etc
L /var/opt/piavpn/plugins - - - - /usr/libexec/piavpn/opt/piavpn/plugins
L /var/opt/piavpn/qml - - - - /usr/libexec/piavpn/opt/piavpn/qml
L /var/opt/piavpn/share - - - - /usr/libexec/piavpn/opt/piavpn/share
L /var/opt/piavpn/var - - - - /var/lib/piavpn
EOF

# --- MISSION 4: EXTRACTION & STORE ---
mkdir -p /usr/libexec/piavpn
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/libexec/piavpn/

# --- MISSION 5: SYSTEM INTEGRATION & YOUR MASTER FIX ---
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d /usr/share/applications /usr/share/pixmaps

# Replicating your successful Workstation steps
cp /usr/libexec/piavpn/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/libexec/piavpn/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/libexec/piavpn/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png
cp /usr/libexec/piavpn/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# APPLY THE WORKINGDIRECTORY FIX
sed -i 's|ExecStart=.*|ExecStart=/opt/piavpn/bin/pia-daemon|' /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a WorkingDirectory=/opt/piavpn' /usr/lib/systemd/system/piavpn.service
# Diplomatic Passport for SELinux Enforcing mode
sed -i '/\[Service\]/a SELinuxContext=system_u:system_r:unconfined_t:s0' /usr/lib/systemd/system/piavpn.service

# --- MISSION 6: PERMISSIONS & FINALIZE ---
setcap 'cap_net_bind_service=+ep' /usr/libexec/piavpn/opt/piavpn/bin/pia-unbound || true
chown 1000:0 /usr/libexec/piavpn/opt/piavpn/bin/pia-client || true
chown 1000:0 /usr/libexec/piavpn/opt/piavpn/bin/piactl || true

systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

