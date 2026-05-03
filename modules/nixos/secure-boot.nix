{ inputs, ... }: {
  flake.nixosModules.secure-boot = { config, pkgs, lib, ... }:
  let
    secureBootState = builtins.fromJSON (builtins.readFile ./secure-boot-state.json);
    secureBootEnabled = config.custom.secureBoot.enable || (secureBootState.enable or false);
  in {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
    ];

    options.custom.secureBoot.enable = lib.mkEnableOption "Lanzaboote Secure Boot";

    config = lib.mkMerge [
      {
        environment.systemPackages = [ pkgs.sbctl ];
      }
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
