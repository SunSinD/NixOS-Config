#
# hosts/vm/configuration.nix
# ──────────────────────────
# The "vm" host: a portable virtual machine config that boots cleanly under
# VMware, QEMU/KVM (VirtIO), and similar hypervisors. Pulls in the shared
# core via the import at the bottom.
#
{ inputs, ... }: {
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };

    modules = [
      ({ pkgs, ... }: {
        nixpkgs.hostPlatform = "x86_64-linux";
        networking.hostName  = "vm";
        # Secure Boot rarely makes sense in a VM; kept off.
        custom.secureBoot.enable = false;

        # ── Hardware ─────────────────────────────────────────────────────────
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
        # VMware's vmwgfx needs 3D acceleration enabled in the VM settings.
        boot.initrd.kernelModules = [ "vmwgfx" ];
        # Both KVM modules included since the VM may run on AMD or Intel hosts.
        boot.kernelModules        = [ "kvm-amd" "kvm-intel" ];

        # ── Boot ─────────────────────────────────────────────────────────────
        # Latest mainline kernel + systemd-boot on the EFI partition.
        boot = {
          kernelPackages              = pkgs.linuxPackages_latest;
          supportedFilesystems        = [ "btrfs" ];
          initrd.supportedFilesystems = [ "btrfs" ];

          loader.systemd-boot.enable      = true;
          loader.efi.canTouchEfiVariables = true;
        };

        # ── VM guest integration ─────────────────────────────────────────────
        # Clipboard sharing, dynamic resolution, time sync, etc.
        services.spice-vdagentd.enable     = true;
        services.qemuGuest.enable          = true;
        virtualisation.vmware.guest.enable = true;

        environment.systemPackages = with pkgs; [
          spice-vdagent
          open-vm-tools
          mesa-demos
          wlr-randr
        ];
      })
    ] ++ builtins.attrValues inputs.self.nixosModules;
  };
}
