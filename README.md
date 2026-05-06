# NixOS Config

## Hosts

| Host | Description |
|------|-------------|
| `main-pc` | Desktop - AMD/Nvidia, CachyOS kernel, Secure Boot ready |
| `vm` | VM - QEMU/SPICE/VMware guest tools |
| `generic` | Portable - works on any UEFI laptop/desktop |

## Install

Connect to Wi-Fi:

```bash
nmtui
```

Run the installer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

VMs are auto-detected.
