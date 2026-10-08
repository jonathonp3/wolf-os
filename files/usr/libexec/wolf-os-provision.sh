#!/usr/bin/bash
# First-boot provisioning.

set -euo pipefail

MARKER="/etc/wolf-os/wolf-os-provisioned"

echo "Wolf-OS: provisioning template..."

systemctl daemon-reload
systemctl enable --now sshd.service 2>/dev/null || :
systemctl enable --now docker.service 2>/dev/null || :
systemctl enable --now wolf-os-optimization.service 2>/dev/null || :


# --- 5. Write the provisioning marker ---------------------------------
mkdir -p /etc/wolf-os
touch "$MARKER"

echo "Wolf-OS: template provisioning complete"
