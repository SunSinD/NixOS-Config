{ inputs, withSystem, ... }: {
  flake.nixosConfigurations.generic = withSystem "x86_64-linux" ({ config, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      system      = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        flakePackages = config.packages;
      };

      modules = [
        ({ pkgs, lib, ... }: {
          networking.hostName = "generic";

          # ── Disk ───────────────────────────────────────────────────────────────
          # Placeholder — install script always provides the actual device.
          custom.disk.device = "/dev/sda";

          # ── Hardware ───────────────────────────────────────────────────────────
          # Broad module coverage for unknown hardware
          boot.initrd.availableKernelModules = [
            "ahci"
            "xhci_pci"
            "thunderbolt"
            "nvme"
            "usb_storage"
            "uas"
            "usbhid"
            "sd_mod"
            "sdhci_pci"
            "mmc_block"
            "virtio_pci"
            "virtio_blk"
          ];
          boot.kernelModules                 = [ "kvm-amd" "kvm-intel" ];
          hardware.cpu.amd.updateMicrocode   = lib.mkDefault true;
          hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
          services.fstrim.enable             = true;
          services.fwupd.enable              = false;

          # ── Boot ───────────────────────────────────────────────────────────────
          boot = {
            kernelPackages              = pkgs.linuxPackages_latest;
            supportedFilesystems        = [ "btrfs" ];
            initrd.supportedFilesystems = [ "btrfs" ];

            loader = {
              efi.canTouchEfiVariables = false;
              timeout = lib.mkForce 0;
              systemd-boot = {
                enable = true;
                configurationLimit = lib.mkForce 1;
              };
            };
          };

          custom.secureBoot.enable = false;
        })
      ] ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
