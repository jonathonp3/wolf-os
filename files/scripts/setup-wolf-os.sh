#!/bin/bash
set -euo pipefail

# --- 1. PRE-INSTALL IDENTITY ---
# Create groups in the build factory
groupadd -r docker || true
groupadd -r libvirt-qemu || true
groupadd -r virtnetwork || true

# --- 2. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."

# Ensure clean up script is executable
chmod +x /usr/libexec/wolf-os-firstboot.sh

# --- 3. FINALISE ---
systemctl enable \
    libvirtd.service \
    virtlogd.service \
    virtnetworkd.service \
    virtstoraged.service \
    virtnodedevd.socket \
    sshd.service \
    docker.service \
    wolf-os-cleanup.service \
    app-tmpfiles.service

echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

