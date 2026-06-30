#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS PIA Assembly..."

# --- 1. PRE-INSTALL IDENTITY ---
# Create groups in the build factory
groupadd -r piavpn || true
groupadd -r piahnsd || true
groupadd -r docker || true
groupadd -r libvirt-qemu || true
groupadd -r virtnetwork || true

# ---- 2. EXTRACT & STORE ---
mkdir -p /usr/libexec/piavpn
tar -xpJf /tmp/files/tmp/pia-backup.tar.xz -C /usr/libexec/piavpn/

# --- 3: SYSTEM INTEGRATION ---
mkdir -p /usr/lib/systemd/system /usr/lib/NetworkManager/conf.d /usr/share/applications /usr/share/pixmaps

# --- 4. Replicating successful Workstation steps
cp /usr/libexec/piavpn/etc/systemd/system/piavpn.service /usr/lib/systemd/system/piavpn.service
cp /usr/libexec/piavpn/usr/share/applications/piavpn.desktop /usr/share/applications/piavpn.desktop
cp /usr/libexec/piavpn/usr/share/pixmaps/piavpn.png /usr/share/pixmaps/piavpn.png
# NetworkManager drop-ins under /usr/lib are shipped as part of the immutable image
# so the config is always present even if /etc isn't populated/persisted the way we expect.
cp /usr/libexec/piavpn/etc/NetworkManager/conf.d/wgpia.conf /usr/lib/NetworkManager/conf.d/wgpia.conf

ln -sf /usr/libexec/piavpn/opt/piavpn/bin/piactl /usr/bin/piactl
ln -sf /usr/libexec/piavpn/opt/piavpn/bin/pia-daemon /usr/bin/pia-daemon
ln -sf /usr/libexec/piavpn/opt/piavpn/bin/pia-client /usr/bin/pia-client
ln -sf /usr/libexec/piavpn/opt/piavpn/bin/pia-unbound /usr/bin/pia-unbound

# --- 5. SET WORKING DIRECTORY ---
sed -i '/\[Service\]/a WorkingDirectory=/opt/piavpn' /usr/lib/systemd/system/piavpn.service

# --- 6. SET PERMISSIONS
setcap 'cap_net_bind_service=+ep' /usr/libexec/piavpn/opt/piavpn/bin/pia-unbound || true

chown root:piavpn /usr/libexec/piavpn/opt/piavpn/bin/pia-client
chown root:piavpn /usr/libexec/piavpn/opt/piavpn/bin/piactl
chmod 755 /usr/libexec/piavpn/opt/piavpn/bin/pia-client
chmod 755 /usr/libexec/piavpn/opt/piavpn/bin/piactl

# --- 7. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."

# Ensure clean up script is executable
chmod +x /usr/libexec/wolf-os-firstboot.sh

# --- 8. FINALISE ---
systemctl enable libvirtd.service virtlogd.service virtnetworkd.service virtstoraged.service virtnodedevd.socket piavpn.service sshd.service docker.service wolf-os-cleanup.service apps-tmpfiles.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

