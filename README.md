# NixOS Config

### Wi-Fi

```bash
nmcli device wifi connect "wifi" password "password"
```

### Install

Boot the installer in UEFI mode. Disable Secure Boot for the first install.

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh)
```

For most laptops and desktops, use the generic host:

```bash
bash <(curl -sL raw.githubusercontent.com/SunSinD/NixOS-Config/main/install.sh) generic
```

`main-pc` is desktop-specific and uses AMD/Nvidia/CachyOS settings.

### Lanzaboote Secure Boot

Lanzaboote must be enabled after the first successful systemd-boot boot.

After first boot:

```bash
enable-lanzaboote
```

Then reboot into firmware setup, put Secure Boot into Setup Mode, boot NixOS again, and run:

```bash
sudo sbctl enroll-keys --microsoft
```

Reboot and enable Secure Boot if firmware did not enable it automatically.

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
