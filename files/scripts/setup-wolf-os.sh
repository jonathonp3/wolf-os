#!/bin/bash
set -euo pipefail

echo "🚀 Starting Wolf-OS PIA Assembly..."

# --- 1. PRE-INSTALL IDENTITY ---
RUN groupadd -r libvirt-qemu || true && \
    groupadd -r piavpn || true && \
    groupadd -r piahnsd || true && \
    groupadd -r docker || true && \
    groupadd -r virtnetwork || true

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

# --- 7. SET WORKING DIRECTORY ---
sed -i '/\[Service\]/a WorkingDirectory=/opt/piavpn' /usr/lib/systemd/system/piavpn.service

# --- 8. SET PERMISSIONS
setcap 'cap_net_bind_service=+ep' /usr/libexec/piavpn/opt/piavpn/bin/pia-unbound || true

chown root:piavpn /usr/libexec/piavpn/opt/piavpn/bin/pia-client
chown root:piavpn /usr/libexec/piavpn/opt/piavpn/bin/piactl
chmod 755 /usr/libexec/piavpn/opt/piavpn/bin/pia-client
chmod 755 /usr/libexec/piavpn/opt/piavpn/bin/piactl

# --- 10. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."

# Ensure clean up script is executable
chmod +x /usr/libexec/wolf-os-firstboot.sh

# --- 10. FINALISE ---
systemctl enable libvirtd.service virtlogd.service virtnetworkd.service virtstoraged.service virtnodedevd.socket piavpn.service sshd.service docker.service wolf-os-cleanup.service piavpn-tmpfiles.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

