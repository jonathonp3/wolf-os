#!/bin/bash
set -euo pipefail

# --- 1. PRE-INSTALL IDENTITY ---
groupadd -r docker || true

# --- 2. DISTROBOX / SYSROOT MOUNT FIX ---
# Distrobox 1.8.2.5 emits ":ro:rslave" for read-only bind mounts when
# /sysroot is present (ostree/bootc). Podman 6.2 requires comma-separated
# mount options. Keep the original behavior when rslave is empty.
DISTROBOX_CREATE=/usr/bin/distrobox-create
if [ -f "$DISTROBOX_CREATE" ] && grep -qF ':ro${rslave}' "$DISTROBOX_CREATE"; then
    sed -i 's|:ro${rslave}|:ro${rslave:+","}${rslave#:}|' "$DISTROBOX_CREATE"
    echo "🔧 Patched Distrobox read-only volume syntax"
fi
if [ -f "$DISTROBOX_CREATE" ] && ! grep -qF ':ro${rslave:+","}${rslave#:}' "$DISTROBOX_CREATE"; then
    echo "❌ Distrobox patch did not apply cleanly" >&2
    exit 1
fi

# --- 3. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."
chmod +x /usr/libexec/wolf-os-optimization.sh
chmod +x /usr/libexec/wolf-os-provision.sh

# --- 4. ENABLE SYSTEMD UNITS IN THE VENDOR LAYER ---
mkdir -p /usr/lib/systemd/system/multi-user.target.wants

ln -sf ../wolf-os-provision.service \
    /usr/lib/systemd/system/multi-user.target.wants/wolf-os-provision.service


echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

