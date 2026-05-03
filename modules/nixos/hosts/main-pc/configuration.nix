{ inputs, withSystem, ... }: {
  flake.nixosConfigurations.main-pc = withSystem "x86_64-linux" ({ config, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      system      = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        flakePackages = config.packages;
      };

      modules = [
        ({ pkgs, lib, ... }: {
          networking.hostName = "main-pc";
          custom.secureBoot.enable = false;

          # ── Disk ───────────────────────────────────────────────────────────────
          # Only needed for manual disko re-runs. Install script overrides this.
          custom.disk.device = "/dev/disk/by-id/nvme-KINGSTON_SNV2S1000G_50026B778557B959";

          # ── Hardware ───────────────────────────────────────────────────────────
          boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
          boot.kernelModules                 = [ "kvm-amd" ];
          hardware.cpu.amd.updateMicrocode   = true;

          # ── CachyOS kernel ─────────────────────────────────────────────────────
          nixpkgs.overlays    = [ inputs.nix-cachyos-kernel.overlays.pinned ];
          boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

          # ── Extra binary caches for CachyOS packages ────────────────────────────
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

          # ── Nvidia ─────────────────────────────────────────────────────────────
          services.xserver.videoDrivers = [ "nvidia" ];

          hardware.nvidia = {
            open               = true;
            modesetting.enable = true;
          };

          # ── Boot ───────────────────────────────────────────────────────────────
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

            #consoleLogLevel = 0;
            #kernelParams    = [ "quiet" "udev.log_level=0" "rd.systemd.show_status=false" "rd.udev.log_level=0" ];
          };

          systemd.network.wait-online.enable = false;

          # ── Secure boot keys ───────────────────────────────────────────────────
        })
      ] ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
