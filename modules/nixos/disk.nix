#
# disk.nix
# ────────
# Declarative disk layout + filesystem mounts.
#
# install.sh does the *initial* partitioning itself (parted + mkfs). This
# module describes the same layout so the system knows how to mount it:
#   - disko: GPT, ESP for /boot, btrfs for everything else with subvolumes.
#     Only used if you re-run disko by hand to repartition.
#   - fileSystems (below): mounts those subvolumes by LABEL, so the same
#     config works on any machine without changing device paths.
#
{ ... }: {
  flake.nixosModules.disk = { lib, config, ... }: {

    # The disk device is only needed if you want to re-run disko manually
    # to repartition an existing installation.
    options.custom.disk.device = lib.mkOption {
      type        = lib.types.str;
      default     = "/dev/sda";
      description = ''
        Disk device used when re-running disko manually.
        Not used for normal system operation — filesystems mount by label.
        Override with the actual disk path if repartitioning.
      '';
    };

    config = {
      # ── Disko partition layout ─────────────────────────────────────────────
      # Mirrors what install.sh creates. Only used for manual repartitioning.
      disko.devices.disk.main = {
        type   = "disk";
        device = config.custom.disk.device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type         = "filesystem";
                format       = "vfat";
                mountpoint   = "/boot";
                extraArgs    = [ "-F" "32" "-n" "NIXBOOT" ];
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size    = "100%";
              content = {
                type      = "btrfs";
                extraArgs = [ "-f" "--label" "nixos" ];
                subvolumes = {
                  "@" = {
                    mountpoint   = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint   = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint   = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@log" = {
                    mountpoint   = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@snapshots" = {
                    mountpoint   = "/.snapshots";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };

      # ── Label-based fileSystems ────────────────────────────────────────────
      # These override whatever disko auto-generates from device paths.
      # By using labels, the config works on any hardware without modification.
      # As long as the disk is formatted with the correct labels (which the
      # install script ensures), these mounts will always work.
      fileSystems = lib.mkForce {
        "/" = {
          device  = "LABEL=nixos";
          fsType  = "btrfs";
          options = [ "subvol=@" "compress=zstd" "noatime" ];
        };
        "/nix" = {
          device  = "LABEL=nixos";
          fsType  = "btrfs";
          options = [ "subvol=@nix" "compress=zstd" "noatime" ];
        };
        "/home" = {
          device  = "LABEL=nixos";
          fsType  = "btrfs";
          options = [ "subvol=@home" "compress=zstd" "noatime" ];
        };
        "/var/log" = {
          device  = "LABEL=nixos";
          fsType  = "btrfs";
          options = [ "subvol=@log" "compress=zstd" "noatime" ];
        };
        "/.snapshots" = {
          device  = "LABEL=nixos";
          fsType  = "btrfs";
          options = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
        };
        "/boot" = {
          device  = "/dev/disk/by-label/NIXBOOT";
          fsType  = "vfat";
          options = [ "umask=0077" ];
        };
      };
    };
  };
}
