#!/bin/bash

# Remove the default Flatpak version
flatpak uninstall --system -y org.gnome.TextEditor || true

# Any other first-boot cleanup tasks can go here
echo "Wolf-OS cleanup complete."

