#
# secure-boot.nix
# ───────────────
# Optional Secure Boot via Lanzaboote.
#
# Lanzaboote replaces systemd-boot with a signed bootloader so that UEFI
# Secure Boot can verify the kernel + initrd before they run.
#
# The on/off toggle reads from TWO places, joined with OR:
#   1. `custom.secureBoot.enable` (set in a host's configuration.nix)
#   2. modules/nixos/secure-boot-state.json {"enable": true/false}
#      (written by `scripts/enable-lanzaboote.sh` so a normal user can flip
#      Secure Boot on without editing Nix.)
#
{ inputs, ... }: {
  flake.nixosModules.secure-boot = { config, pkgs, lib, ... }:
  let
    secureBootState = builtins.fromJSON (builtins.readFile ./secure-boot-state.json);
    secureBootEnabled = config.custom.secureBoot.enable || (secureBootState.enable or false);
  in {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

    # Defines the per-host toggle: `custom.secureBoot.enable = true;`
    options.custom.secureBoot.enable = lib.mkEnableOption "Lanzaboote Secure Boot";

    config = lib.mkMerge [
      # Always ship `sbctl` (the CLI used to enroll keys / sign EFI files).
      {
        environment.systemPackages = [ pkgs.sbctl ];
      }
      # When Secure Boot is on: turn off systemd-boot and use Lanzaboote
      # instead, signing kernels/initrds with keys stored in /var/lib/sbctl.
      (lib.mkIf secureBootEnabled {
        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      })
    ];
  };
}
