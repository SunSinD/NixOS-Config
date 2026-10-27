#
# hosts/main-pc/configuration.nix
# ───────────────────────────────
# The "main-pc" host: my AMD CPU + Nvidia GPU desktop running the CachyOS
# kernel. This file only contains things that DIFFER from the shared core
# (modules/nixos/core.nix); everything else is inherited via the import
# at the bottom (`builtins.attrValues inputs.self.nixosModules`).
#
{ inputs, ... }: {
  flake.nixosConfigurations.main-pc = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = [
      ({ pkgs, ... }: {
        nixpkgs.hostPlatform = "x86_64-linux";
        # Identifies the host on the network and in the boot menu label.
        networking.hostName  = "main-pc";
        # Secure Boot off here; flip on with `enable-lanzaboote` after install.
        custom.secureBoot.enable = false;

        # ── Virtualization ───────────────────────────────────────────────────
        # Only enabled here so portable hosts (e.g. "generic") can't break
        # upgrades due to TPM-sealed systemd credentials on libvirt/swtpm.
        virtualisation = {
          libvirtd = {
            enable            = true;
            qemu.swtpm.enable = true;
          };
          spiceUSBRedirection.enable = true;
        };

        # ── Disk ─────────────────────────────────────────────────────────────
        # Only needed for manual disko re-runs (see modules/nixos/disk.nix).
        custom.disk.device = "/dev/disk/by-id/nvme-KINGSTON_SNV2S1000G_50026B778557B959";

        # ── Hardware ─────────────────────────────────────────────────────────
        boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
        boot.kernelModules                 = [ "kvm-amd" ];
        hardware.cpu.amd.updateMicrocode   = true;

        # ── CachyOS kernel ───────────────────────────────────────────────────
        nixpkgs.overlays    = [ inputs.nix-cachyos-kernel.overlays.pinned ];
        boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

        # ── Extra binary caches for CachyOS packages ─────────────────────────
        nix.settings = {
          extra-substituters = [
            "https://attic.xuyh0120.win/lantian"
            "https://cache.garnix.io"
          ];
          extra-trusted-public-keys = [
            "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          ];
        };

        # ── Nvidia ───────────────────────────────────────────────────────────
        services.xserver.videoDrivers = [ "nvidia" ];

        hardware.nvidia = {
          open               = true;
          modesetting.enable = true;
        };

        # ── Boot ─────────────────────────────────────────────────────────────
        # Boot menu hidden (timeout 0, hold Space at boot to show it) and up
        # to 10 generations kept.
        boot = {
          supportedFilesystems        = [ "btrfs" ];
          initrd.supportedFilesystems = [ "btrfs" ];

          loader = {
            efi.canTouchEfiVariables = true;
            timeout                  = 0;
            systemd-boot = {
              enable             = true;
              configurationLimit = 10;
            };
          };

          initrd.systemd = {
            enable                     = true;
            network.wait-online.enable = false;
          };
        };
      })
    ] ++ builtins.attrValues inputs.self.nixosModules;
  };
}
