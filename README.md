# NixOS Config

### Install

```bash
bash <(curl -sL sunsind.github.io/NixOS-Config/install.sh)
```

### Update

```bash
update
```

This pulls the latest changes from GitHub and rebuilds the system automatically.

### Rebuild (without pulling)

```bash
rebuild
```

### Update flake inputs

```bash
nix flake update --flake ~/nixconf
```
