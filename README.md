# NixOS Config

### Wi-Fi

```bash
nmcli device wifi connect "wifi" password "password"
```

### Install

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

For most laptops and desktops, use the generic host:

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh) generic
```

`main-pc` is desktop-specific and uses AMD/Nvidia/CachyOS/Secure Boot settings.
For `generic`, disable Secure Boot in firmware setup before installing.

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
