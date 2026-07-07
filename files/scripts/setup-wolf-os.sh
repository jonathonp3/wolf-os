#!/bin/bash
set -euo pipefail

# --- 1. PRE-INSTALL IDENTITY ---
groupadd -r docker || true
groupadd -r libvirt-qemu || true
groupadd -r virtnetwork || true

# --- 2. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."
chmod +x /usr/libexec/wolf-os-firstboot.sh

# --- 3. VPN ---
echo "⚙️ Enabling PIA VPN Auto-Provisioner..."
chmod +x /usr/libexec/piavpn-installer.sh

# --- 4. FINALISE ---
systemctl enable \
    libvirtd.service \
    virtlogd.service \
    virtnetworkd.service \
    virtstoraged.service \
    virtnodedevd.socket \
    sshd.service \
    docker.service \
    wolf-os-cleanup.service \
    apps-tmpfiles.service \
    piavpn-provision.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

