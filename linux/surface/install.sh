#!/usr/bin/env bash
# linux-surface kernel + touch/pen daemon for the Surface Pro 7.
# Upstream instructions: https://github.com/linux-surface/linux-surface/wiki/Installation-and-Setup
#
# Skips everything when a surface kernel is already running. Reboot afterwards
# and pick the surface kernel in the boot menu if it is not the default.
set -euo pipefail

SURFACE_KEY_URL="https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc"

if uname -r | grep -q surface; then
  echo "Already running a linux-surface kernel ($(uname -r)); nothing to do."
  exit 0
fi

install_dnf() {
  sudo dnf config-manager addrepo --overwrite \
    --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo
  sudo dnf install -y --allowerasing kernel-surface iptsd libwacom-surface
}

install_apt() {
  curl -fsSL "$SURFACE_KEY_URL" | gpg --dearmor \
    | sudo dd of=/etc/apt/trusted.gpg.d/linux-surface.gpg
  echo "deb [arch=amd64] https://pkg.surfacelinux.com/debian release main" \
    | sudo tee /etc/apt/sources.list.d/linux-surface.list
  sudo apt-get update
  sudo apt-get install -y linux-image-surface linux-headers-surface libwacom-surface iptsd
}

if command -v dnf >/dev/null 2>&1; then
  install_dnf
elif command -v apt-get >/dev/null 2>&1; then
  install_apt
else
  echo "Unsupported distro; follow the linux-surface wiki for manual setup." >&2
  exit 1
fi

# iptsd starts per device via udev (iptsd@.service), so no unit to enable
echo "linux-surface installed. Reboot to switch kernels."
