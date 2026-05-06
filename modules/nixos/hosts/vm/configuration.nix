{ inputs, withSystem, ... }: {
  flake.nixosConfigurations.vm = withSystem "x86_64-linux" ({ config, ... }:
    inputs.nixpkgs.lib.nixosSystem {
      system      = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        flakePackages = config.packages;
      };

      modules = [
        ({ pkgs, ... }: {
          networking.hostName = "vm";
          custom.secureBoot.enable = false;

          # Disk
          # Placeholder only. The installer mounts filesystems by label.
          custom.disk.device = "/dev/sda";

          # Hardware
          # Covers VMware, QEMU/KVM VirtIO, SATA, and common SCSI boot disks.
          boot.initrd.availableKernelModules = [
            "ahci"
            "ata_piix"
            "sd_mod"
            "sr_mod"
            "xhci_pci"
            "ehci_pci"
            "ohci_pci"
            "usbhid"
            "virtio_pci"
            "virtio_blk"
            "virtio_scsi"
            "mptbase"
            "mptscsih"
            "mptspi"
            "vmw_pvscsi"
          ];
          boot.initrd.kernelModules = [ "vmwgfx" ];
          boot.kernelModules       = [ "kvm-amd" "kvm-intel" ];

          # Boot
          boot = {
            kernelPackages              = pkgs.linuxPackages_latest;
            supportedFilesystems        = [ "btrfs" ];
            initrd.supportedFilesystems = [ "btrfs" ];

            loader.systemd-boot.enable       = true;
            loader.efi.canTouchEfiVariables  = true;
          };

          # VM guest integration
          services.spice-vdagentd.enable = true;
          services.qemuGuest.enable      = true;
          virtualisation.vmware.guest.enable = true;

          # VMware Wayland compatibility
          # VMware's vmwgfx needs 3D acceleration enabled in VMware settings.
          # These variables ensure proper rendering and cursor behavior.
          environment.sessionVariables = {
            WLR_NO_HARDWARE_CURSORS = "1";
          };

          environment.systemPackages = [
            pkgs.spice-vdagent
            pkgs.open-vm-tools
            pkgs.mesa-demos
          ];
        })
      ] ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
