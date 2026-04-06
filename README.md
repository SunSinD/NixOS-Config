# nixos-config

My personal NixOS configuration using Flakes, niri, DankMaterialShell, and Home Manager.

## Structure

- `flake.nix` — entry point, declares all inputs and the system
- `configuration.nix` — system-level config (boot, networking, packages)
- `home.nix` — user-level config (terminal, git, niri keybinds, DMS)

## To rebuild after pulling changes
```bash
cd ~/nixos-config && git pull
sudo nixos-rebuild switch --flake ~/nixos-config#SunSD
```

## Fresh install steps

1. Boot NixOS minimal ISO
2. Partition, format and mount your disk
3. Run `nixos-generate-config --root /mnt`
4. Clone this repo: `git clone https://github.com/YOURUSERNAME/nixos-config ~/nixos-config`
5. Copy hardware config: `cp /mnt/etc/nixos/hardware-configuration.nix ~/nixos-config/`
6. Add hardware import to configuration.nix
7. Run `nixos-install --flake ~/nixos-config#SunSD`