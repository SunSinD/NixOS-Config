# NixOS Config

My NixOS setup: niri (tiling Wayland compositor) + Noctalia shell, managed as a flake with Home Manager.

## Hosts

| Host | Description |
|------|-------------|
| `main-pc` | Desktop - AMD/Nvidia, CachyOS kernel, Secure Boot ready |
| `vm` | VM - QEMU/SPICE/VMware guest tools |
| `generic` | Portable - works on any UEFI laptop/desktop |

## Install

Boot the NixOS ISO in UEFI mode, then connect to Wi-Fi:

```bash
nmtui
```

Run the installer (it wipes the target disk):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

VMs are auto-detected. The config is copied to `~/nixconf` on the new system.

## Commands

| Command | What it does |
|---------|--------------|
| `update` | Pull the latest config from GitHub and rebuild |
| `rebuild` | Rebuild from the local `~/nixconf` |
| `enable-lanzaboote` | Turn on Secure Boot (Lanzaboote) |
| `finish-install` | Post-install menu (Secure Boot setup, key enrollment) |

## Layout

```
flake.nix               inputs + auto-imports everything in modules/
install.sh              installer (partition, install, reboot)
modules/nixos/          system: core settings, disk layout, Secure Boot
modules/nixos/hosts/    per-machine settings
modules/apps/           apps, niri, Noctalia, helper scripts
scripts/                update / Secure Boot scripts (used by the aliases)
assets/                 wallpapers and profile picture
```
