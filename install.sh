#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/SunSinD/NixOS-Config.git"
WORK_DIR="/tmp/nixconf"
HOST="${1:-}"

# ── Host selection ────────────────────────────────────────────────────────────
if [[ -z "$HOST" || "$HOST" == "--help" || "$HOST" == "-h" ]]; then
  echo "Select a host to install:"
  echo "  [0] main-pc  — full desktop, Nvidia, CachyOS kernel, Secure Boot"
  echo "  [1] vm       — full desktop, QEMU/SPICE guest tools, standard kernel"
  echo "  [2] generic  — full desktop, portable hardware config, standard kernel"
  read -rp "Choice (number): " HOST_CHOICE
  case "$HOST_CHOICE" in
    0) HOST="main-pc" ;;
    1) HOST="vm"      ;;
    2) HOST="generic" ;;
    *) echo "ERROR: Invalid choice."; exit 1 ;;
  esac
fi

case "$HOST" in
  main-pc|vm|generic) ;;
  *)
    echo "ERROR: Unknown host '$HOST'. Choose: main-pc, vm, or generic."
    exit 1 ;;
esac

# ── Cleanup on exit ───────────────────────────────────────────────────────────
cleanup() { sudo umount -R /mnt 2>/dev/null || true; }
trap cleanup EXIT

# ── 1. Clone config ───────────────────────────────────────────────────────────
echo "==> Fetching config ($HOST)..."
rm -rf "$WORK_DIR"
git clone -q "$REPO" "$WORK_DIR"
cd "$WORK_DIR"

exec < /dev/tty

# ── 2. Require UEFI ───────────────────────────────────────────────────────────
if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "ERROR: UEFI firmware required. BIOS/Legacy is not supported."
  exit 1
fi
echo "==> Firmware: UEFI"

# ── 3. Disk selection ─────────────────────────────────────────────────────────
ISO_DISK=$(findmnt -n -o SOURCE /iso 2>/dev/null | xargs -r lsblk -no PKNAME 2>/dev/null || true)

mapfile -t DISK_NAMES < <(
  lsblk -dn -o NAME,TYPE -e 7 \
    | awk '$2=="disk"{print $1}' \
    | grep -v "^${ISO_DISK}$" \
  || true
)
[[ ${#DISK_NAMES[@]} -eq 0 ]] && { echo "ERROR: No eligible disks found."; exit 1; }

if [[ ${#DISK_NAMES[@]} -eq 1 ]]; then
  DEV="/dev/${DISK_NAMES[0]}"
  echo "==> Disk: $DEV  $(lsblk -dno SIZE "$DEV")  $(lsblk -dno MODEL "$DEV")"
else
  echo "Available disks:"
  for i in "${!DISK_NAMES[@]}"; do
    printf "  [%d] /dev/%s  %s  %s\n" "$i" \
      "${DISK_NAMES[$i]}" \
      "$(lsblk -dno SIZE  "/dev/${DISK_NAMES[$i]}")" \
      "$(lsblk -dno MODEL "/dev/${DISK_NAMES[$i]}")"
  done
  read -rp "DANGER: This will WIPE the selected disk. Choose (number): " CHOICE
  [[ -z "${DISK_NAMES[$CHOICE]+x}" ]] && { echo "ERROR: Invalid choice."; exit 1; }
  DEV="/dev/${DISK_NAMES[$CHOICE]}"
fi

# ── 4. Partition and format with disko ────────────────────────────────────────
echo "==> Partitioning and formatting $DEV..."

DISKO_CONFIG=$(mktemp /tmp/disko-XXXXXX.nix)
cat > "$DISKO_CONFIG" << NIXEOF
{
  disko.devices.disk.main = {
    type   = "disk";
    device = "$DEV";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type         = "filesystem";
            format       = "vfat";
            mountpoint   = "/boot";
            extraArgs    = [ "-F" "32" "-n" "NIXBOOT" ];
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size    = "100%";
          content = {
            type      = "btrfs";
            extraArgs = [ "-f" "--label" "nixos" ];
            subvolumes = {
              "@"          = { mountpoint = "/";           mountOptions = [ "compress=zstd" "noatime" ]; };
              "@nix"       = { mountpoint = "/nix";        mountOptions = [ "compress=zstd" "noatime" ]; };
              "@home"      = { mountpoint = "/home";       mountOptions = [ "compress=zstd" "noatime" ]; };
              "@log"       = { mountpoint = "/var/log";    mountOptions = [ "compress=zstd" "noatime" ]; };
              "@snapshots" = { mountpoint = "/.snapshots"; mountOptions = [ "compress=zstd" "noatime" ]; };
            };
          };
        };
      };
    };
  };
}
NIXEOF

sudo nix --extra-experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest' -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks \
  "$DISKO_CONFIG" &>/dev/null || true

rm -f "$DISKO_CONFIG"

echo "==> Installing NixOS ($HOST)... (this may take 10-20 minutes)"
sudo nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$HOST" \
  --no-root-passwd \
  --option substituters         "https://cache.nixos.org https://attic.xuyh0120.win/lantian https://cache.garnix.io" \
  --option trusted-public-keys  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" \
  2>&1 | grep -v "^warning:\|^\+\|^$\|Removed input" || true

# ── 6. Persist config on installed system ─────────────────────────────────────
DEST="/mnt/home/SunSD/nixconf"
sudo mkdir -p "$(dirname "$DEST")"
sudo cp -rT "$WORK_DIR" "$DEST"
sudo chown -R 1000:1000 "$DEST"
cd "$DEST" && sudo -u "#1000" git remote set-url origin https://github.com/SunSinD/NixOS-Config.git 2>/dev/null || true

echo "==> Done! Rebooting..."
sudo reboot
