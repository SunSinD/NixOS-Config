# NixOS Config

### Wi-Fi

```bash
nmcli device wifi connect "wifi" password "password"
```

### Install

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

For a ThinkPad, use the ThinkPad host directly:

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh) thinkpad
```

`main-pc` is desktop-specific and uses AMD/Nvidia/CachyOS/Secure Boot settings.
For `thinkpad` and `generic`, disable Secure Boot in firmware setup before installing.

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
