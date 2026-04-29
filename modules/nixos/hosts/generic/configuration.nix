{ inputs, withSystem, ... }: {
  flake.nixosConfigurations.generic = withSystem "x86_64-linux" ({ config, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      system      = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        flakePackages = config.packages;
      };

      modules = [
        ({ pkgs, ... }: {
          networking.hostName = "generic";

          # ── Disk ───────────────────────────────────────────────────────────────
          # Placeholder — install script always provides the actual device.
          custom.disk.device = "/dev/sda";

          # ── Hardware ───────────────────────────────────────────────────────────
          # Broad module coverage for unknown hardware
          boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" "virtio_pci" "virtio_blk" ];
          boot.kernelModules                 = [ "kvm-amd" "kvm-intel" ];

          # ── Boot ───────────────────────────────────────────────────────────────
          boot = {
            kernelPackages              = pkgs.linuxPackages_latest;
            supportedFilesystems        = [ "btrfs" ];
            initrd.supportedFilesystems = [ "btrfs" ];

            loader = {
              efi.canTouchEfiVariables = true;
              timeout = 0;
              systemd-boot = {
                enable = true;
                configurationLimit = 10;
              };
            };
          };
        })
      ] ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
