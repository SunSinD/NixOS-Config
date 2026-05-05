#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/SunSinD/NixOS-Config.git"
WORK_DIR="/mnt/tmp/nixconf"
INSTALL_TMPDIR="/mnt/tmp"
USER_CACHE_DIR="/mnt/tmp/nix-cache-user"
ROOT_CACHE_DIR="/mnt/tmp/nix-cache-root"
HOST="${1:-}"
DISKO_CONFIG=""
INSTALL_SUBSTITUTERS="https://cache.nixos.org https://niri.cachix.org https://attic.xuyh0120.win/lantian https://cache.garnix.io"
INSTALL_TRUSTED_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="

filter_install_output() {
  sed -E '/^warning:/d;/^\+/d;/^[[:space:]]*$/d;/(Added|Adding|Removed) input/d'
}

detect_machine() {
  local file value
  for file in /sys/class/dmi/id/product_name /sys/class/dmi/id/product_family /sys/class/dmi/id/sys_vendor; do
    [[ -r "$file" ]] || continue
    value="$(<"$file")"
    [[ -n "$value" ]] && printf '%s\n' "$value"
  done
}

secure_boot_enabled() {
  local file value

  if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state 2>/dev/null | grep -qi "SecureBoot enabled" && return 0
  fi

  for file in /sys/firmware/efi/efivars/SecureBoot-*; do
    [[ -e "$file" ]] || continue
    value="$(od -An -t u1 "$file" 2>/dev/null | awk '{print $5; exit}')"
    [[ "$value" == "1" ]] && return 0
  done

  return 1
}

find_efi_loader() {
  local file

  for file in \
    /mnt/boot/EFI/systemd/systemd-bootx64.efi \
    /mnt/boot/EFI/BOOT/BOOTX64.EFI
  do
    [[ -f "$file" ]] && { printf '%s\n' "$file"; return 0; }
  done

  if compgen -G "/mnt/boot/EFI/NixOS-boot/*.efi" >/dev/null; then
    mapfile -t NIXOS_BOOTLOADERS < <(compgen -G "/mnt/boot/EFI/NixOS-boot/*.efi")
    printf '%s\n' "${NIXOS_BOOTLOADERS[0]}"
    return 0
  fi

  while IFS= read -r file; do
    [[ -f "$file" ]] && { printf '%s\n' "$file"; return 0; }
  done < <(find /mnt/nix/store -path '*/lib/systemd/boot/efi/systemd-bootx64.efi' -type f 2>/dev/null)

  while IFS= read -r file; do
    [[ -f "$file" ]] && { printf '%s\n' "$file"; return 0; }
  done < <(find /nix/store /run/current-system/sw -path '*/lib/systemd/boot/efi/systemd-bootx64.efi' -type f 2>/dev/null)

  return 1
}

build_systemd_loader() {
  local out

  out="$(
    nix --extra-experimental-features "nix-command flakes" \
      build --no-link --print-out-paths 'nixpkgs#systemd' 2>/dev/null \
    || nix --extra-experimental-features "nix-command flakes" \
      build --no-link --print-out-paths 'github:NixOS/nixpkgs/nixos-unstable#systemd'
  )"

  if [[ -f "$out/lib/systemd/boot/efi/systemd-bootx64.efi" ]]; then
    printf '%s\n' "$out/lib/systemd/boot/efi/systemd-bootx64.efi"
    return 0
  fi

  return 1
}

prepare_install_workspace() {
  echo "==> Preparing install workspace on target disk..."
  sudo mkdir -p "$INSTALL_TMPDIR" "$USER_CACHE_DIR" "$ROOT_CACHE_DIR"
  sudo chmod 1777 "$INSTALL_TMPDIR" "$USER_CACHE_DIR" "$ROOT_CACHE_DIR"

  export TMPDIR="$INSTALL_TMPDIR"
  export XDG_CACHE_HOME="$USER_CACHE_DIR"

  sudo rm -rf "$WORK_DIR"
  git clone -q "$REPO" "$WORK_DIR"
  cd "$WORK_DIR"
}

cleanup() {
  local status=$?
  [[ -n "$DISKO_CONFIG" ]] && rm -f "$DISKO_CONFIG"

  if [[ "$status" -ne 0 ]]; then
    echo "==> Install failed. Leaving /mnt mounted for debugging."
    echo "==> Useful checks: findmnt /mnt /mnt/boot; sudo find /mnt/boot -maxdepth 5 -type f"
    return
  fi

  sudo umount -R /mnt 2>/dev/null || true
}
trap cleanup EXIT

# Host selection
if [[ -z "$HOST" || "$HOST" == "--help" || "$HOST" == "-h" ]]; then
  echo "Select a host to install:"
  echo "  [0] main-pc - desktop-only, AMD/Nvidia, CachyOS kernel"
  echo "  [1] vm      - full desktop, QEMU/SPICE guest tools, standard kernel"
  echo "  [2] generic - portable laptop/desktop config, standard kernel"
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

MACHINE="$(detect_machine | tr '\n' ' ' || true)"
if [[ "$HOST" == "main-pc" && "$MACHINE" == *ThinkPad* ]]; then
  echo "ERROR: This machine looks like a ThinkPad: $MACHINE"
  echo "main-pc is desktop-only (AMD/Nvidia/CachyOS/Secure Boot). Use: generic"
  exit 1
fi

if [[ -r /dev/tty ]]; then
  exec < /dev/tty
fi

# Require UEFI
if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "ERROR: UEFI firmware required. BIOS/Legacy is not supported."
  exit 1
fi
echo "==> Firmware: UEFI"

if [[ "$HOST" != "main-pc" ]] && secure_boot_enabled; then
  echo "ERROR: Secure Boot is enabled."
  echo "$HOST uses an unsigned EFI bootloader, which most firmware will reject with Secure Boot enabled."
  echo "Disable Secure Boot in firmware setup, then run this installer again."
  exit 1
fi

# Disk selection
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

# Partition and format with disko
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
  "$DISKO_CONFIG" \
  2>&1 | filter_install_output

rm -f "$DISKO_CONFIG"
DISKO_CONFIG=""

if ! findmnt /mnt >/dev/null; then
  echo "ERROR: disko finished but /mnt is not mounted."
  exit 1
fi

if ! findmnt /mnt/boot >/dev/null; then
  echo "ERROR: disko finished but /mnt/boot (EFI system partition) is not mounted."
  exit 1
fi

prepare_install_workspace

echo "==> Installing NixOS ($HOST)... (this may take 10-20 minutes)"
sudo env TMPDIR="$INSTALL_TMPDIR" XDG_CACHE_HOME="$ROOT_CACHE_DIR" \
  nixos-install \
  --root /mnt \
  --flake "$WORK_DIR#$HOST" \
  --no-root-passwd \
  --option substituters         "$INSTALL_SUBSTITUTERS" \
  --option trusted-public-keys  "$INSTALL_TRUSTED_KEYS" \
  2>&1 | filter_install_output

echo "==> Verifying EFI boot files..."
if [[ ! -s /mnt/boot/EFI/BOOT/BOOTX64.EFI ]]; then
  EFI_LOADER="$(find_efi_loader || true)"

  if [[ -z "$EFI_LOADER" ]] && command -v bootctl >/dev/null 2>&1; then
    sudo bootctl --esp-path=/mnt/boot install || true
    EFI_LOADER="$(find_efi_loader || true)"
  fi

  if [[ -z "$EFI_LOADER" ]]; then
    echo "==> Fetching systemd-boot EFI loader..."
    EFI_LOADER="$(build_systemd_loader || true)"
  fi

  if [[ -z "$EFI_LOADER" ]]; then
    echo "ERROR: No EFI loader found to install as fallback /EFI/BOOT/BOOTX64.EFI."
    find /mnt/boot/EFI -maxdepth 3 -type f 2>/dev/null || true
    find /mnt/nix/store -path '*/lib/systemd/boot/efi/*.efi' -type f 2>/dev/null | head -n 20 || true
    exit 1
  fi

  sudo mkdir -p /mnt/boot/EFI/BOOT
  sudo mkdir -p /mnt/boot/EFI/systemd
  sudo cp "$EFI_LOADER" /mnt/boot/EFI/systemd/systemd-bootx64.efi
  sudo cp "$EFI_LOADER" /mnt/boot/EFI/BOOT/BOOTX64.EFI
fi

BOOT_ENTRY="$(sudo find /mnt/boot/loader/entries -maxdepth 1 -type f -name '*.conf' -print -quit 2>/dev/null || true)"
UKI_ENTRY="$(sudo find /mnt/boot/EFI/Linux -maxdepth 1 -type f -name '*.efi' -print -quit 2>/dev/null || true)"

if [[ -z "$BOOT_ENTRY" && -z "$UKI_ENTRY" ]]; then
  echo "WARNING: No systemd-boot entry files were visible in /mnt/boot."
  echo "nixos-install already finished, so this warning will not stop the install."
  echo "Boot files currently on the EFI partition:"
  sudo find /mnt/boot -maxdepth 5 -type f 2>/dev/null || true
fi

if command -v efibootmgr >/dev/null 2>&1; then
  echo "==> Firmware boot entries:"
  sudo efibootmgr -v || true
fi

# Persist config on installed system
DEST="/mnt/home/SunSD/nixconf"
sudo mkdir -p "$(dirname "$DEST")"
sudo cp -rT "$WORK_DIR" "$DEST"
sudo chown -R 1000:1000 "$DEST"
cd "$DEST" && sudo -u "#1000" git remote set-url origin https://github.com/SunSinD/NixOS-Config.git 2>/dev/null || true

echo "==> Done! Rebooting..."
sudo reboot
