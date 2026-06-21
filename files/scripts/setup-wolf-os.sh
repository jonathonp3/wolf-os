#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS PIA Assembly..."

# --- 1. IDENTITY ---
mkdir -p /usr/lib/sysusers.d
cat <<EOF > /usr/lib/sysusers.d/wolf-os.conf
g piavpn - -
g piahnsd - -
# Add jonathon to libvirt group
m jonathon libvirt
# m jonathon piavpn
EOF

# --- 3: WIRING & SECURITY BLUEPRINT ---
echo "🔗 Configuring Declarative Wiring and Security Trust..."
mkdir -p /usr/lib/tmpfiles.d
cat <<EOF > /usr/lib/tmpfiles.d/piavpn.conf
# 1. Folders for VPN and Security
d /var/lib/piavpn 0775 root piavpn -
d /var/run/piavpn 0775 root piavpn -
d /var/opt/piavpn 0755 root root -
d /var/opt/piavpn/etc 0775 root piavpn -
d /etc/containers 0755 root root -
d /etc/pki/containers 0755 root root -

# 2. VPN LINKS: Bridge /var back to the immutable /usr store
L /var/opt/piavpn/bin - - - - /usr/libexec/piavpn/opt/piavpn/bin
L /var/opt/piavpn/lib - - - - /usr/libexec/piavpn/opt/piavpn/lib
L /var/opt/piavpn/plugins - - - - /usr/libexec/piavpn/opt/piavpn/plugins
L /var/opt/piavpn/qml - - - - /usr/libexec/piavpn/opt/piavpn/qml
L /var/opt/piavpn/share - - - - /usr/libexec/piavpn/opt/piavpn/share
L /var/opt/piavpn/var - - - - /var/lib/piavpn

# 3. SECURITY COPIES: Automate the 'Signed' rebase trust
# Use 'L' (Link) instead of 'C' (Copy) to FORCE the system to use policy
L /etc/containers/policy.json - - - - /usr/etc/containers/policy.json
L /etc/pki/containers/wolf-os.pub - - - - /usr/etc/pki/containers/wolf-os.pub
EOF

# ---- 4. EXTRACT & STORE ---
mkdir -p /usr/libexec/piavpn
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/libexec/piavpn/

# --- 5: SYSTEM INTEGRATION ---
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d /usr/share/applications /usr/share/pixmaps

# --- 6. Replicating successful Workstation steps
cp /usr/libexec/piavpn/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/libexec/piavpn/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/libexec/piavpn/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png
cp /usr/libexec/piavpn/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

# --- 7. APPLY THE WORKING DIRECTORY FIX - TESTED ON WORKSTATION ---
sed -i 's|ExecStart=.*|ExecStart=/opt/piavpn/bin/pia-daemon|' /usr/lib/systemd/system/piavpn.service
sed -i '/\[Service\]/a WorkingDirectory=/opt/piavpn' /usr/lib/systemd/system/piavpn.service

# --- 8. SET PERMISSIONS & FINALISE ---
setcap 'cap_net_bind_service=+ep' /usr/libexec/piavpn/opt/piavpn/bin/pia-unbound || true
chown 1000:0 /usr/libexec/piavpn/opt/piavpn/bin/pia-client || true
chown 1000:0 /usr/libexec/piavpn/opt/piavpn/bin/piactl || true

systemctl enable libvirtd.service virtlogd.service piavpn.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

