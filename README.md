# Nixos-Config

My personal NixOS configuration, fully declarative, version-controlled, and reproducible.
Built with Flakes, niri, DankMaterialShell, and Home Manager.

---

## Structure

---

## Quick Rebuild
```bash
cd ~/nixos-config && git pull
sudo nixos-rebuild switch --flake ~/nixos-config#SunSD
```

---

## System Info

|---|---|
| Host | SunSD |
| OS | NixOS (unstable) |
| Compositor | niri |
| Shell | DankMaterialShell (DMS) |
| Terminal | Ghostty |
| Browser | Vivaldi |

---

## Fresh Install (Step by Step)

### 1. Boot

Boot the NixOS minimal ISO. Log in as root:
```bash
sudo -i
```

Check internet:
```bash
ping -c 3 google.com
```

---

### 2. Partition the Disk

Check your disk name first:
```bash
lsblk
```

Open the partition editor (replace sda with your disk if different):
```bash
cfdisk /dev/sda
```

Inside cfdisk:
- Select `gpt`
- New → `512M` → Type: `EFI System`
- New → remaining space → Type: `Linux filesystem`
- Write → yes → Quit

---

### 3. Format
```bash
mkfs.fat -F 32 /dev/sda1
mkfs.ext4 /dev/sda2
```

---

### 4. Mount
```bash
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
```

---

### 5. Generate Hardware Config
```bash
nixos-generate-config --root /mnt
```

---

### 6. Clone This Repo
```bash
nix-shell -p git --run "git clone https://github.com/SunSinD/nixos-config /mnt/etc/nixos/nixos-config"
```

---

### 7. Copy Hardware Config Into Repo
```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-config/
```

---

### 8. Add Hardware Import to configuration.nix
```bash
nano /mnt/etc/nixos/nixos-config/configuration.nix
```

Change `imports = [];` to:
```nix
imports = [
  ./hardware-configuration.nix
];
```

Save: Ctrl+O, Enter, Ctrl+X

---

### 9. Install
```bash
cd /mnt/etc/nixos/nixos-config
git add .
nixos-install --flake /mnt/etc/nixos/nixos-config#SunSD
```

Set a root password when prompted.

---

### 10. Reboot
```bash
reboot
```

Log in as `sun` with password `changeme`, then immediately change it:
```bash
passwd
```

---

### 11. Move Repo to Home Folder
```bash
cp -r /etc/nixos/nixos-config ~/nixos-config
```

---

### 12. Set Up DMS
```bash
dms setup
```

Select: Niri → Ghostty → systemd → yes

---

### 13. Launch Desktop
```bash
niri-session
```

---

## Keybinds

| Keybind | Action |
|---|---|
| Super + Enter | Open Ghostty terminal |
| Super + Q | Close focused window |
| Super + Space | Open DMS app launcher |
| Super + Left/Right/Up/Down | Move focus between windows |

---

## Common Commands

| Command | What it does |
|---|---|
| `sudo nixos-rebuild switch --flake ~/nixos-config#SunSD` | Apply config changes |
| `sudo nixos-rebuild switch --rollback` | Undo last change |
| `nix-collect-garbage -d` | Free up disk space |
| `nix flake update` | Update all inputs to latest |

---

## Adding Packages

System-wide: add to `environment.systemPackages` in `configuration.nix`

User-only: add to `home.packages` in `home.nix`

Search packages at https://search.nixos.org/packages

Then rebuild:
```bash
cd ~/nixos-config && git pull
sudo nixos-rebuild switch --flake ~/nixos-config#SunSD
```

---

## Resources

- https://nixos.org/manual/nixos/stable/
- https://nixos-and-flakes.thiscute.world/
- https://search.nixos.org/packages
- https://wiki.nixos.org/
- https://danklinux.com/docs/
- https://github.com/YaLTeR/niri/wiki

