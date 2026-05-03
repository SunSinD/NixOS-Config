#!/usr/bin/env bash
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
    bash "$HOME/nixconf/scripts/enable-lanzaboote.sh" "$HOST"
    ;;
  2)
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
