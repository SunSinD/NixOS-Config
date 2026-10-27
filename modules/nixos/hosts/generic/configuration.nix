#
# hosts/generic/configuration.nix
# ───────────────────────────────
# The "generic" host: a portable config meant to boot on any UEFI laptop or
# desktop. It loads broad sets of kernel modules and supports both Intel and
# AMD CPUs/microcode, making it the safe default when you don't know the
# exact hardware.
#
{ inputs, ... }: {
  flake.nixosConfigurations.generic = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = [
      ({ pkgs, lib, ... }: {
        nixpkgs.hostPlatform = "x86_64-linux";
        networking.hostName  = "generic";

        # ── Hardware ─────────────────────────────────────────────────────────
        # Broad module coverage for unknown hardware.
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
        # Both KVM modules so this image can host virtualization on any CPU.
        boot.kernelModules                 = [ "kvm-amd" "kvm-intel" ];
        # Apply the latest CPU microcode whichever vendor is present.
        hardware.cpu.amd.updateMicrocode   = lib.mkDefault true;
        hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
        # Periodic SSD TRIM. fwupd off by default to keep the image small.
        services.fstrim.enable             = true;
        services.fwupd.enable              = false;

        # ── Boot ─────────────────────────────────────────────────────────────
        # Mainline kernel; systemd-boot writes only to /boot, never to NVRAM
        # (`canTouchEfiVariables = false`) so this image is safe on borrowed
        # or locked-down hardware.
        boot = {
          kernelPackages              = pkgs.linuxPackages_latest;
          supportedFilesystems        = [ "btrfs" ];
          initrd.supportedFilesystems = [ "btrfs" ];

          loader = {
            efi.canTouchEfiVariables = false;
            systemd-boot.enable      = true;
          };
        };

        # Secure Boot stays off here since this image targets unknown UEFIs.
        custom.secureBoot.enable = false;
      })
    ] ++ builtins.attrValues inputs.self.nixosModules;
  };
}
