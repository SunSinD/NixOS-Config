#!/usr/bin/env bash
# enable-lanzaboote.sh — flip Secure Boot ON for this install.
#
# Usage: enable-lanzaboote [host]   (defaults to $(hostname))
#
# Steps:
#   1. Sanity-check that this is a UEFI system + the host config exists.
#   2. Create Secure Boot signing keys in /var/lib/sbctl (idempotent).
#   3. Write {"enable": true} to secure-boot-state.json so the
#      modules/nixos/secure-boot.nix toggle picks it up.
#   4. Rebuild the system with Lanzaboote replacing systemd-boot.
#
# After this, you reboot into firmware setup, put Secure Boot into "Setup
# Mode", boot back into NixOS, and run `finish-install` to enroll keys.

set -euo pipefail

HOST="${1:-$(hostname)}"
CONFIG="$HOME/nixconf/modules/nixos/hosts/$HOST/configuration.nix"
STATE="$HOME/nixconf/modules/nixos/secure-boot-state.json"

# ── Preflight checks ────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Host config not found: $CONFIG"
  echo "Usage: enable-lanzaboote [main-pc|generic|vm]"
  exit 1
fi

if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "ERROR: UEFI boot required."
  exit 1
fi

# ── Create signing keys (only if missing) ──────────────────────────────────
if [[ ! -d /var/lib/sbctl/keys ]]; then
  echo "==> Creating Secure Boot keys in /var/lib/sbctl..."
  sudo sbctl create-keys
fi

# ── Flip the Secure Boot toggle ON via the JSON state file ─────────────────
cat > "$STATE" << 'EOF'
{
  "enable": true
}
EOF

# ── Build & switch to the Lanzaboote-enabled config ────────────────────────
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
