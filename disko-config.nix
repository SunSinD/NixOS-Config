{ lib, ... }: {
  # Disko replaces manual partitioning, formatting, and mounting.
  # It reads this file and sets up your disk automatically.
  disko.devices = {
    disk = {
      # "main" is just a name we give this disk — can be anything
      main = {
        type = "disk";
        # lib.mkDefault means "use this unless overridden elsewhere"
        # sda is your VirtualBox virtual disk
        device = lib.mkDefault "/dev/nvme0n1";
        content = {
          # GPT = modern partition table (required for EFI/systemd-boot)
          type = "gpt";
          partitions = {
            # Boot partition — stores the bootloader
            ESP = {
              size = "512M";
              type = "EF00"; # EF00 = EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat"; # FAT32, required for EFI
                mountpoint = "/boot";
              };
            };
            # Root partition — stores NixOS and everything else
            root = {
              size = "100%"; # Use all remaining space
              content = {
                type = "filesystem";
                format = "ext4"; # Standard Linux filesystem
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
