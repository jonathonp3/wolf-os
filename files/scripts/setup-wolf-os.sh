#!/bin/bash
set -euo pipefail

# --- 1. PRE-INSTALL IDENTITY ---
groupadd -r docker || true

# --- 2. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."
chmod +x /usr/libexec/wolf-os-firstboot.sh

# --- 3. VPN ---
echo "⚙️ Enabling PIA VPN post install..."
chmod +x /usr/libexec/piavpn-deploy.sh
chmod +x /usr/lib/systemd/system/piavpn-extract.service

# --- 4. FINALISE ---
systemctl enable \
    virtlogd.service \
    virtnetworkd.service \
    virtstoraged.service \
    virtnodedevd.socket \
    sshd.service \
    docker.service \
    wolf-os-cleanup.service \
    apps-tmpfiles.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

