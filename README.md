### Installation: 

```bash
bash <(curl -sL greyxp1.github.io/nixconf/install.sh)
```

### To rebuild the system:

```bash
cd ~/nixconf/ && git pull
```

```bash
sudo nixos-rebuild switch --flake ~/nixconf#main-pc
```

### To update the system:

```bash
nix flake update --flake ~/nixconf
```

```bash
sudo nixos-rebuild switch --flake ~/nixconf#main-pc
```
