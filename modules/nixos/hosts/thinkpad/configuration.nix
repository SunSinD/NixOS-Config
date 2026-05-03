{ inputs, withSystem, ... }: {
  flake.nixosConfigurations.thinkpad = withSystem "x86_64-linux" ({ config, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        flakePackages = config.packages;
      };

      modules = [
        ({ pkgs, lib, ... }: {
          networking.hostName = "thinkpad";

          # Only needed for manual disko re-runs. Install script overrides this.
          custom.disk.device = "/dev/nvme0n1";

          boot.initrd.availableKernelModules = [
            "nvme"
            "xhci_pci"
            "thunderbolt"
            "usb_storage"
            "usbhid"
            "sd_mod"
            "ahci"
          ];
          boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

          hardware.cpu.amd.updateMicrocode = lib.mkDefault true;
          hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

          boot = {
            kernelPackages = pkgs.linuxPackages_latest;
            supportedFilesystems = [ "btrfs" ];
            initrd.supportedFilesystems = [ "btrfs" ];

            loader = {
              efi.canTouchEfiVariables = true;
              timeout = lib.mkForce 3;
              systemd-boot = {
                enable = true;
                configurationLimit = 10;
              };
            };
          };

          services = {
            fwupd.enable = true;
            fstrim.enable = true;
          };
        })
      ] ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
