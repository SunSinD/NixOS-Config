#!/usr/bin/env bash
# finish-install.sh — interactive post-install wizard.
#
# Usage: finish-install [host]
#
# Offers three choices:
#   [0] do nothing,
#   [1] turn on Lanzaboote Secure Boot (delegates to enable-lanzaboote.sh),
#   [2] enroll the generated keys into firmware (sbctl enroll-keys).
#
# Step [2] should be done AFTER step [1] AND after putting the UEFI into
# Setup Mode in the firmware menu.

set -euo pipefail

HOST="${1:-$(hostname)}"

if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "ERROR: UEFI boot required."
  exit 1
fi

echo "Post-install setup"
echo "  [0] Nothing else"
echo "  [1] Enable Lanzaboote Secure Boot"
echo "  [2] Enroll Secure Boot keys"
read -rp "Choice (number): " CHOICE

case "$CHOICE" in
  0)
    echo "Done."
    ;;
  1)
    # Delegate to the dedicated Lanzaboote enabler script.
    bash "$HOME/nixconf/scripts/enable-lanzaboote.sh" "$HOST"
    ;;
  2)
    # Enroll our generated Secure Boot keys plus Microsoft's UEFI CA so
    # firmware updates and Windows dual-boot keep working.
    if [[ ! -d /var/lib/sbctl/keys ]]; then
      echo "ERROR: No sbctl keys found. Run choice [1] first."
      exit 1
    fi

    sudo sbctl enroll-keys --microsoft
    sudo sbctl status
    ;;
  *)
    echo "ERROR: Invalid choice."
    exit 1
    ;;
esac
