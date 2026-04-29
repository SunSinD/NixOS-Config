{ ... }: {
  flake.nixosModules.disk = { lib, config, inputs, ... }: {

    # The disk device is only needed if you want to re-run disko manually
    # to repartition an existing installation. The install script always
    # provides this via --disk main <device> at install time.
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
      # Used by the install script (via disko standalone) and available for
      # manual repartitioning. The device is overridden at install time.
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
