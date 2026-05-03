#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-$(hostname)}"
CONFIG="$HOME/nixconf/modules/nixos/hosts/$HOST/configuration.nix"
STATE="$HOME/nixconf/modules/nixos/secure-boot-state.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Host config not found: $CONFIG"
  echo "Usage: enable-lanzaboote [main-pc|generic|vm]"
  exit 1
fi

if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "ERROR: UEFI boot required."
  exit 1
fi

if [[ ! -d /var/lib/sbctl/keys ]]; then
  echo "==> Creating Secure Boot keys in /var/lib/sbctl..."
  sudo sbctl create-keys
fi

cat > "$STATE" << 'EOF'
{
  "enable": true
}
EOF

echo "==> Rebuilding with Lanzaboote..."
sudo nixos-rebuild switch --flake "$HOME/nixconf#$HOST"

echo ""
echo "Lanzaboote is built and boot files are signed."
echo "Next:"
echo "  1. Reboot into firmware setup."
echo "  2. Put Secure Boot into Setup Mode."
echo "  3. Boot NixOS again."
echo "  4. Run: finish-install"
echo "  5. Reboot and enable Secure Boot if firmware did not enable it automatically."
echo ""
sudo sbctl verify || true
