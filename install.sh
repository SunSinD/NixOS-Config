#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
REPO="https://github.com/SunSinD/NixOS-Config.git"
WORK_DIR="/mnt/tmp/nixconf"
INSTALL_TMPDIR="/mnt/tmp"
USER_CACHE_DIR="/mnt/tmp/nix-cache-user"
ROOT_CACHE_DIR="/mnt/tmp/nix-cache-root"
ROOT_HOME_DIR="/mnt/tmp/nix-root-home"
INSTALL_SWAPFILE="/mnt/.install-swap"
HOST="${1:-}"

SUBSTITUTERS="https://cache.nixos.org https://niri.cachix.org https://attic.xuyh0120.win/lantian https://cache.garnix.io"
TRUSTED_KEYS="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964= lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
MAX_JOBS=1
CORES=1
SWAP_SIZE="${INSTALL_SWAP_SIZE:-}"
PROGRESS_INTERVAL="${INSTALL_PROGRESS_INTERVAL:-20}"

GREEN=$'\033[32m'
RESET=$'\033[0m'

NIX_FLAGS=(
  --extra-experimental-features "nix-command flakes"
  --store /mnt
  --option substituters "$SUBSTITUTERS"
  --option trusted-public-keys "$TRUSTED_KEYS"
  --option max-jobs "$MAX_JOBS"
  --option cores "$CORES"
  --option fallback false
)

# ── Helpers ───────────────────────────────────────────────────────────────────
msg()    { printf '  - %s\n' "$*" > /dev/tty 2>/dev/null || printf '  - %s\n' "$*"; }
status() { printf '%b==>%b %s\n' "$GREEN" "$RESET" "$*" > /dev/tty 2>/dev/null || printf '==> %s\n' "$*"; }

elapsed() { printf '%dm%02ds' "$(($1 / 60))" "$(($1 % 60))"; }

target_summary() {
  local d s
  d="$(df -h /mnt 2>/dev/null | awk 'NR==2{printf "/mnt %s, %s free",$5,$4}' || true)"
  s="$(swapon --show=NAME,SIZE,USED --noheadings 2>/dev/null | awk 'NR==1{printf "swap %s/%s",$3,$2}' || true)"
  printf '%s | %s' "${d:-/mnt not mounted}" "${s:-swap inactive}"
}

# Single awk filter — avoids pipefail issues with chained greps
filter_output() {
  awk '
    /^[[:space:]]*$/ { next }
    /^\+/ { next }
    /^building the flake in / { next }
    /^unpacking / { next }
    /^copying path / { next }
    /^Create subvolume / { next }
    /^evaluation warning:/ { warn=1; next }
    /^warning:/ && !/download/ { warn=1; next }
    warn && /^[[:space:]]/ { next }
    { warn=0 }
    /(Added|Adding|Removed) input/ { next }
    /^[[:space:]]*follows/ { next }
    /^[[:space:]]/ && (index($0,"github:") || index($0,"https:") || index($0,"path:")) { next }
    { print }
  '
}

run_with_heartbeat() {
  local label="$1"; shift
  msg "$label"
  "$@" &
  local pid=$! start
  start="$(date +%s)"
  while kill -0 "$pid" 2>/dev/null; do
    sleep "$PROGRESS_INTERVAL"
    kill -0 "$pid" 2>/dev/null || break
    msg "$(elapsed $(($(date +%s) - start))) | $(target_summary)"
  done
  wait "$pid"
  msg "Done in $(elapsed $(($(date +%s) - start)))"
}

# ── Machine detection ─────────────────────────────────────────────────────────
detect_machine() {
  local f v=""
  for f in /sys/class/dmi/id/product_name /sys/class/dmi/id/product_family /sys/class/dmi/id/sys_vendor; do
    [[ -r "$f" ]] && v+="$(<"$f") "
  done
  printf '%s' "${v% }"
}

secure_boot_enabled() {
  if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state 2>/dev/null | grep -qi "SecureBoot enabled" && return 0
  fi
  local f val
  for f in /sys/firmware/efi/efivars/SecureBoot-*; do
    [[ -e "$f" ]] || continue
    val="$(od -An -t u1 "$f" 2>/dev/null | awk '{print $5; exit}')"
    [[ "$val" == "1" ]] && return 0
  done
  return 1
}

# ── Partitioning ──────────────────────────────────────────────────────────────
partition_path() {
  local n="$1" p
  p="$(lsblk -nrpo NAME,PARTN "$DEV" 2>/dev/null | awk -v n="$n" '$2==n{print $1;exit}')"
  if [[ -n "$p" ]]; then echo "$p"
  elif [[ "$DEV" =~ [0-9]$ ]]; then echo "${DEV}p${n}"
  else echo "${DEV}${n}"
  fi
}

format_and_mount() {
  local efi root
  sudo swapoff -a 2>/dev/null || true
  sudo umount -R /mnt 2>/dev/null || true

  sudo wipefs -af "$DEV" >/dev/null
  sudo parted -s "$DEV" mklabel gpt >/dev/null
  sudo parted -s "$DEV" mkpart ESP fat32 1MiB 513MiB >/dev/null
  sudo parted -s "$DEV" set 1 esp on >/dev/null
  sudo parted -s "$DEV" mkpart root btrfs 513MiB 100% >/dev/null
  sudo partprobe "$DEV" 2>/dev/null || true
  sudo udevadm settle 2>/dev/null || sleep 2

  efi="$(partition_path 1)"
  root="$(partition_path 2)"
  [[ -b "$efi" && -b "$root" ]] || { echo "ERROR: Partitions not found after formatting."; lsblk "$DEV" || true; exit 1; }

  sudo mkfs.vfat -F 32 -n NIXBOOT "$efi" >/dev/null
  sudo mkfs.btrfs -f -L nixos "$root" >/dev/null

  sudo mkdir -p /mnt
  sudo mount "$root" /mnt
  local sv; for sv in @ @nix @home @log @snapshots; do
    sudo btrfs subvolume create "/mnt/$sv" >/dev/null
  done
  sudo umount /mnt

  sudo mount -o compress=zstd,noatime,subvol=@ "$root" /mnt
  sudo mkdir -p /mnt/{nix,home,var/log,.snapshots,boot}
  sudo mount -o compress=zstd,noatime,subvol=@nix       "$root" /mnt/nix
  sudo mount -o compress=zstd,noatime,subvol=@home      "$root" /mnt/home
  sudo mount -o compress=zstd,noatime,subvol=@log       "$root" /mnt/var/log
  sudo mount -o compress=zstd,noatime,subvol=@snapshots "$root" /mnt/.snapshots
  sudo mount -o umask=0077 "$efi" /mnt/boot
}

# ── Swap ──────────────────────────────────────────────────────────────────────
auto_swap_size() {
  local disk_gib
  disk_gib="$(lsblk -b -dn -o SIZE "$DEV" 2>/dev/null | awk '{printf "%d", $1/1073741824}')"
  if [[ "$disk_gib" =~ ^[0-9]+$ ]] && (( disk_gib < 50 )); then
    echo "4G"
  else
    echo "8G"
  fi
}

enable_swap() {
  if swapon --show=NAME --noheadings 2>/dev/null | grep -qx "$INSTALL_SWAPFILE"; then
    return 0
  fi
  local size="${SWAP_SIZE:-$(auto_swap_size)}"
  msg "Enabling temporary swap ($size)"
  sudo rm -f "$INSTALL_SWAPFILE"
  if ! sudo btrfs filesystem mkswapfile --size "$size" "$INSTALL_SWAPFILE" >/dev/null 2>&1; then
    sudo touch "$INSTALL_SWAPFILE"
    sudo chattr +C "$INSTALL_SWAPFILE" 2>/dev/null || true
    sudo fallocate -l "$size" "$INSTALL_SWAPFILE"
    sudo chmod 600 "$INSTALL_SWAPFILE"
    sudo mkswap "$INSTALL_SWAPFILE" >/dev/null
  fi
  sudo swapon "$INSTALL_SWAPFILE"
  msg "$(target_summary)"
}

disable_swap() {
  if swapon --show=NAME --noheadings 2>/dev/null | grep -qx "$INSTALL_SWAPFILE"; then
    sudo swapoff "$INSTALL_SWAPFILE" 2>/dev/null || true
  fi
  sudo rm -f "$INSTALL_SWAPFILE" 2>/dev/null || true
}

# ── Nix helpers ───────────────────────────────────────────────────────────────
root_nix() {
  sudo env HOME="$ROOT_HOME_DIR" TMPDIR="$INSTALL_TMPDIR" XDG_CACHE_HOME="$ROOT_CACHE_DIR" \
    nix "${NIX_FLAGS[@]}" "$@"
}

# ── EFI verification ─────────────────────────────────────────────────────────
find_efi_loader() {
  local f
  for f in \
    /mnt/boot/EFI/systemd/systemd-bootx64.efi \
    /mnt/boot/EFI/BOOT/BOOTX64.EFI; do
    [[ -f "$f" ]] && { echo "$f"; return 0; }
  done
  # Search boot partition, installed nix store, and live system store
  f="$(find /mnt/boot/EFI /mnt/nix/store /nix/store /run/current-system/sw \
    -path '*/systemd-bootx64.efi' -type f -print -quit 2>/dev/null || true)"
  [[ -n "$f" ]] && { echo "$f"; return 0; }
  return 1
}

# ── Cleanup ───────────────────────────────────────────────────────────────────
cleanup() {
  local rc=$?
  disable_swap
  if [[ "$rc" -ne 0 ]]; then
    msg "Target: $(target_summary)"
    status "Install failed"
    msg "Leaving /mnt mounted for debugging."
    msg "Useful checks: findmnt /mnt /mnt/boot; sudo find /mnt/boot -maxdepth 5 -type f"
  else
    sudo umount -R /mnt 2>/dev/null || true
  fi
}
trap cleanup EXIT

# ═════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═════════════════════════════════════════════════════════════════════════════
MACHINE="$(detect_machine)"
printf '\033[2J\033[H\n%s\n\n' "SunSD NixOS Installer" > /dev/tty 2>/dev/null || printf '\n%s\n\n' "SunSD NixOS Installer"

# ── Host selection ────────────────────────────────────────────────────────────
if [[ -z "$HOST" && "$MACHINE" =~ (VMware|VirtualBox|KVM|QEMU|Hyper-V|Hypervisor|Bochs) ]]; then
  HOST="vm"
  msg "Host: vm ($MACHINE)"
fi

if [[ -z "$HOST" || "$HOST" == "--help" || "$HOST" == "-h" ]]; then
  echo "Select a host to install:"
  echo "  [0] main-pc - desktop-only, AMD/Nvidia, CachyOS kernel"
  echo "  [1] vm      - full desktop, QEMU/SPICE/VMware guest tools"
  echo "  [2] generic - portable laptop/desktop config"
  read -rp "Choice (number): " choice
  case "$choice" in
    0) HOST="main-pc" ;; 1) HOST="vm" ;; 2) HOST="generic" ;;
    *) echo "ERROR: Invalid choice."; exit 1 ;;
  esac
fi

case "$HOST" in
  main-pc|vm|generic) ;;
  *) echo "ERROR: Unknown host '$HOST'. Choose: main-pc, vm, or generic."; exit 1 ;;
esac

if [[ "$HOST" == "main-pc" && "$MACHINE" == *ThinkPad* ]]; then
  echo "ERROR: This machine looks like a ThinkPad: $MACHINE"
  echo "main-pc is desktop-only (AMD/Nvidia/CachyOS). Use: generic"
  exit 1
fi

[[ -r /dev/tty ]] && exec < /dev/tty

# ── [1/6] Preflight ──────────────────────────────────────────────────────────
[[ -d /sys/firmware/efi/efivars ]] || {
  echo "ERROR: This installer requires UEFI mode."
  echo "Detected: BIOS/Legacy boot. Missing /sys/firmware/efi/efivars."
  if [[ "$MACHINE" =~ VMware ]]; then
    echo "VMware fix: VM Settings > Options > Advanced > Firmware type: UEFI"
  else
    echo "Fix: Enable UEFI boot in firmware settings, disable Legacy/CSM."
  fi
  exit 1
}
status "[1/6] Preflight"
msg "Firmware: UEFI"

if [[ "$HOST" != "main-pc" ]] && secure_boot_enabled; then
  echo "ERROR: Secure Boot is enabled."
  echo "$HOST uses an unsigned bootloader. Disable Secure Boot and retry."
  exit 1
fi

# ── Disk selection ────────────────────────────────────────────────────────────
ISO_DISK=$(findmnt -n -o SOURCE /iso 2>/dev/null | xargs -r lsblk -no PKNAME 2>/dev/null || true)
mapfile -t DISKS < <(lsblk -dn -o NAME,TYPE -e 7 | awk '$2=="disk"{print $1}' | grep -v "^${ISO_DISK}$" || true)
[[ ${#DISKS[@]} -eq 0 ]] && { echo "ERROR: No eligible disks found."; exit 1; }

if [[ ${#DISKS[@]} -eq 1 ]]; then
  DEV="/dev/${DISKS[0]}"
  msg "Disk: $DEV  $(lsblk -dno SIZE "$DEV")  $(lsblk -dno MODEL "$DEV" 2>/dev/null || true)"
else
  echo "Available disks:"
  for i in "${!DISKS[@]}"; do
    printf "  [%d] /dev/%s  %s  %s\n" "$i" "${DISKS[$i]}" \
      "$(lsblk -dno SIZE "/dev/${DISKS[$i]}")" "$(lsblk -dno MODEL "/dev/${DISKS[$i]}" 2>/dev/null || true)"
  done
  read -rp "DANGER: This will WIPE the selected disk. Choose (number): " choice
  [[ -z "${DISKS[$choice]+x}" ]] && { echo "ERROR: Invalid choice."; exit 1; }
  DEV="/dev/${DISKS[$choice]}"
fi

# ── [2/6] Prepare disk ───────────────────────────────────────────────────────
status "[2/6] Prepare disk"
run_with_heartbeat "partitioning and formatting $DEV" format_and_mount 2>&1 | filter_output
findmnt /mnt >/dev/null      || { echo "ERROR: /mnt is not mounted after partitioning."; exit 1; }
findmnt /mnt/boot >/dev/null || { echo "ERROR: /mnt/boot (ESP) is not mounted."; exit 1; }

enable_swap

# ── [3/6] Prepare workspace ──────────────────────────────────────────────────
status "[3/6] Prepare workspace"
sudo mkdir -p "$INSTALL_TMPDIR" "$USER_CACHE_DIR" "$ROOT_CACHE_DIR" "$ROOT_HOME_DIR"
sudo chmod 1777 "$INSTALL_TMPDIR" "$USER_CACHE_DIR"
sudo chmod 700 "$ROOT_CACHE_DIR" "$ROOT_HOME_DIR"
export TMPDIR="$INSTALL_TMPDIR" XDG_CACHE_HOME="$USER_CACHE_DIR"

sudo rm -rf "$WORK_DIR"
git clone -q "$REPO" "$WORK_DIR"
cd "$WORK_DIR"
msg "Target: $(target_summary)"

# ── [4/6] Resolve flake ──────────────────────────────────────────────────────
status "[4/6] Resolve flake inputs"
run_with_heartbeat "fetching locked inputs" \
  root_nix flake metadata --no-write-lock-file "$WORK_DIR" 2>&1 | filter_output
msg "Target: $(target_summary)"

# ── [5/6] Install NixOS ──────────────────────────────────────────────────────
status "[5/6] Install NixOS"
msg "Nix build limits: max-jobs=$MAX_JOBS cores=$CORES"

NIXOS_INSTALL_ARGS=()
nixos-install --help 2>&1 | grep -q -- '--no-write-lock-file' && NIXOS_INSTALL_ARGS+=(--no-write-lock-file)
nixos-install --help 2>&1 | grep -q -- '--no-channel-copy'    && NIXOS_INSTALL_ARGS+=(--no-channel-copy)

run_with_heartbeat "installing NixOS $HOST" \
  sudo env HOME="$ROOT_HOME_DIR" TMPDIR="$INSTALL_TMPDIR" XDG_CACHE_HOME="$ROOT_CACHE_DIR" \
  nixos-install \
    "${NIXOS_INSTALL_ARGS[@]}" \
    --root /mnt \
    --flake "$WORK_DIR#$HOST" \
    --no-root-passwd \
    --option substituters        "$SUBSTITUTERS" \
    --option trusted-public-keys "$TRUSTED_KEYS" \
    --option max-jobs            "$MAX_JOBS" \
    --option cores               "$CORES" \
    --option fallback            false \
  2>&1 | filter_output

# ── [6/6] Verify boot files ──────────────────────────────────────────────────
status "[6/6] Verify boot files"

if [[ ! -s /mnt/boot/EFI/BOOT/BOOTX64.EFI ]]; then
  EFI_LOADER="$(find_efi_loader || true)"

  if [[ -z "$EFI_LOADER" ]] && command -v bootctl >/dev/null 2>&1; then
    sudo bootctl --esp-path=/mnt/boot install 2>/dev/null || true
    EFI_LOADER="$(find_efi_loader || true)"
  fi

  if [[ -z "$EFI_LOADER" ]]; then
    echo "ERROR: No EFI loader found. Boot may fail."
    echo "Files in /mnt/boot/EFI:"
    find /mnt/boot/EFI -maxdepth 3 -type f 2>/dev/null || true
    exit 1
  fi

  sudo mkdir -p /mnt/boot/EFI/{BOOT,systemd}
  sudo cp "$EFI_LOADER" /mnt/boot/EFI/systemd/systemd-bootx64.efi
  sudo cp "$EFI_LOADER" /mnt/boot/EFI/BOOT/BOOTX64.EFI
fi

BOOT_ENTRY="$(sudo find /mnt/boot/loader/entries -maxdepth 1 -type f -name '*.conf' -print -quit 2>/dev/null || true)"
UKI_ENTRY="$(sudo find /mnt/boot/EFI/Linux -maxdepth 1 -type f -name '*.efi' -print -quit 2>/dev/null || true)"

if [[ -z "$BOOT_ENTRY" && -z "$UKI_ENTRY" ]]; then
  echo "WARNING: No boot entries found in /mnt/boot. Boot may fail."
  echo "Files on the EFI partition:"
  sudo find /mnt/boot -maxdepth 5 -type f 2>/dev/null || true
fi

command -v efibootmgr >/dev/null 2>&1 && { msg "Firmware boot entries:"; sudo efibootmgr -v || true; }

# ── Persist config ────────────────────────────────────────────────────────────
DEST="/mnt/home/SunSD/nixconf"
sudo mkdir -p "$(dirname "$DEST")"
sudo cp -rT "$WORK_DIR" "$DEST"
sudo chown -R 1000:1000 "$DEST"
cd "$DEST" && sudo -u "#1000" git remote set-url origin "$REPO" 2>/dev/null || true

status "Done"
msg "Rebooting..."
sudo reboot
