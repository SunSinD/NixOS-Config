# NixOS Config

Personal NixOS flake — Niri compositor, Catppuccin theming, btrfs, systemd-boot.

## Hosts

| Host | Description |
|------|-------------|
| `main-pc` | Desktop — AMD/Nvidia, CachyOS kernel, Secure Boot ready |
| `vm` | VM — QEMU/SPICE/VMware guest tools |
| `generic` | Portable — works on any UEFI laptop/desktop |

## Install

Connect to Wi-Fi (skip if wired):

```bash
nmtui
```

Run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

VMs are auto-detected. On bare metal, the installer will prompt you to pick a host.

You can also pass the host directly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh) generic
```
