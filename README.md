# Wolf-OS

Wolf-OS is my personal OS image built from Fedora Silverblue with Private Internet Access (PIA) APP integrated into the image. It also includes a full virtualization stack, including Docker.

## Components
- Fedora Silverblue (base)
- [Private Internet Access (PIA)](https://www.privateinternetaccess.com)
- Virtualization stack (Docker)

## License
See `LICENSE`


## Installation

The PIA GUI in Wolf-OS is configured to run with UID/GID **1000** (the default group for a new Fedora installation). This setup isn’t intended for multi-user use.


## Step 1. Rebase to Wolf-OS (First Hop (Unverified))

1. Rebase from Fedora Silverblue to the unsigned Wolf-OS image:
```bash
   sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jonathonp3/wolf-os:latest
```

2. Reboot to complete the rebase:
```bash
systemctl reboot
```

## Step 2. Rebase to ostree-image-signed (Second Hop (signed)): 

1. Enable "Factory Merge" moves key and policy into place.
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jonathonp3/wolf-os:latest
```

2. Reboot again to complete the installation
```bash
systemctl reboot
```

## Upgrade 
Upgrade to the latest build
```bash
rpm-ostree upgrade
```

6. Check status
```bash
rpm-ostree status
```

## How to build an ISO

1. Create the installer runtime:

```bash
podman run --pull always --rm ghcr.io/blue-build/cli:latest-installer | bash
```

2. Generate the ISO from the repository image:
```bash
sudo bluebuild generate-iso --iso-name wolf-os iso image ghcr.io/jonathonp3/wolf-os:latest
```

## Rebase to unsigned official Silverblue 44
```bash
sudo rpm-ostree rebase \
  ostree-unverified-registry:quay.io/fedora/fedora-silverblue:44
```

Note: Fedora has moved Silverblue to be delivered as a container (OCI) image, which is pulled via ostree-unverified-registry: rather than the legacy fedora: OSTree remote.

