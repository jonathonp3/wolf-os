#!/bin/bash
echo "🚀 Starting Wolf-OS First-Boot Optimization..."

# 1. Check if the custom remote is already configured
if flatpak remotes | grep -q "wolf-os-apps"; then
    echo "✅ Wolf-OS App Store is already configured. Skipping setup."
else
    # 2. Remove the stock Fedora Flatpak
    echo "🗑️ Removing stock Text Editor..."
    flatpak uninstall --system -y org.gnome.TextEditor || true

    # 3. Add the Wolf-OS Custom App Store
    echo "📦 Connecting to Wolf-OS App Store..."
    wget2 -q -O /tmp/wolf-os-apps.gpg https://raw.githubusercontent.com/jonathonp3/wolf-os-apps/main/wolf-os-apps.gpg
    
    flatpak remote-add --system --if-not-exists --gpg-import=/tmp/wolf-os-apps.gpg wolf-os-apps https://jonathonp3.github.io/wolf-os-apps/
    
    # 4. Install the custom version
    echo "✨ Installing Wolf-OS Custom Text Editor..."
    flatpak install --system -y wolf-os-apps org.gnome.TextEditor
    
    # Clean up GPG key
    rm /tmp/wolf-os-apps.gpg
fi

echo "✅ Wolf-OS first-boot tasks complete."

