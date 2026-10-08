#!/bin/bash
set -euo pipefail

# --- 1. PRE-INSTALL IDENTITY ---
groupadd -r docker || true

# --- 2. AUTOMATED CLEANUP ---
echo "⚙️ Setting up First-Boot cleanup service..."
chmod +x /usr/libexec/wolf-os-optimization.sh
chmod +x /usr/libexec/wolf-os-provision.sh

# --- 3. ENABLE SYSTEMD UNITS IN THE VENDOR LAYER ---
mkdir -p /usr/lib/systemd/system/multi-user.target.wants

ln -sf ../wolf-os-provision.service \
    /usr/lib/systemd/system/multi-user.target.wants/wolf-os-provision.service


echo "✅ Wolf-OS Custom Assembly Complete! Ready for Deployment."

