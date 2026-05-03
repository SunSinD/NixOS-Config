# NixOS Config

## Install

Boot the NixOS ISO in UEFI mode, connect Wi-Fi, then run:

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

The installer asks what to install:

- `generic`: laptops and most desktops
- `main-pc`: my desktop
- `vm`: virtual machines

Keep Secure Boot off for first install. After first boot, run:

```bash
finish-install
```

That finishes optional Lanzaboote Secure Boot setup.

## Commands

- `update`: pull latest config and rebuild
- `rebuild`: rebuild without pulling
- `finish-install`: finish optional post-install setup
