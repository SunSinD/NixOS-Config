# NixOS Config

### WiFi

```bash
nmcli device wifi connect "wifi" password "password"
```

### Install

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
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
