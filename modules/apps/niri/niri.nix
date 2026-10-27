#
# niri.nix
# ────────
# The Niri (scrollable-tiling Wayland compositor) module.
#
# What this file does:
#   1. Reads ./config.kdl (the niri configuration in KDL format).
#   2. Adds the ASUS monitor block on main-pc only (an output that doesn't
#      exist on other machines can leave niri with a blank screen).
#   3. Substitutes @@WALLPAPER_PATH@@ and @@NOCTALIA_SETTINGS_FILE@@
#      placeholders with paths from the Nix store.
#   4. Hands the final config to programs.niri.
#
# The wallpaper, Noctalia and the foot server are started by niri itself
# (see `spawn-at-startup` in config.kdl and `sunsd-session-ensure`).
#
{ inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, config, ... }:
  let
    # The full Noctalia settings JSON, materialised in the Nix store so we
    # can inject its path into the niri environment block.
    noctaliaDeclarativeSettings = pkgs.writeText "noctalia-settings.json" (builtins.readFile ../noctalia/noctalia.json);
    # Avoid carrying store-path context into generated config strings.
    wallpaperPath = builtins.unsafeDiscardStringContext "${../../../assets/wallpapers/clouds.jpg}";

    # To find your exact monitor name, run: niri msg outputs
    mainPcOutputs = ''
      output "ASUS VG279QM" {
          mode "1920x1080@280.000"
      }

    '';

    # Final KDL: host outputs + placeholders replaced with Nix-store paths.
    niriConfigKdl =
      lib.optionalString (config.networking.hostName == "main-pc") mainPcOutputs
      + builtins.replaceStrings
          [ "\r" "@@NOCTALIA_SETTINGS_FILE@@" "@@WALLPAPER_PATH@@" ]
          [ "" "${noctaliaDeclarativeSettings}" wallpaperPath ]
          (builtins.readFile ./config.kdl);
  in {
    imports = [ inputs.niri.nixosModules.niri ];

    # Use the latest unstable build of niri from the niri-flake input.
    programs.niri = {
      enable  = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };

    home-manager.users.SunSD = { ... }: {
      programs.niri.config = niriConfigKdl;
    };
  };
}
