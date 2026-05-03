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

          # ── Disk ───────────────────────────────────────────────────────────────
          # VirtIO block device — standard for QEMU/KVM
          custom.disk.device = "/dev/vda";

          # ── Hardware ───────────────────────────────────────────────────────────
          boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" "virtio_scsi" "ahci" "sd_mod" ];
          boot.kernelModules                 = [ "kvm-amd" "kvm-intel" ];

          # ── Boot ───────────────────────────────────────────────────────────────
          boot = {
            kernelPackages              = pkgs.linuxPackages_latest;
            supportedFilesystems        = [ "btrfs" ];
            initrd.supportedFilesystems = [ "btrfs" ];

            loader.systemd-boot.enable      = true;
            loader.efi.canTouchEfiVariables  = true;
          };

          # ── VM guest tools ─────────────────────────────────────────────────────
          services.spice-vdagentd.enable = true;
          services.qemuGuest.enable      = true;
          environment.systemPackages     = [
            pkgs.spice-vdagent
            pkgs.open-vm-tools
          ];
        })
      ] ++ builtins.attrValues inputs.self.nixosModules;
    }
  );
}
