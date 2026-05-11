#
# noctalia.nix
# ────────────
# Noctalia desktop shell (status bar / launcher / control center / lock
# screen). Reads its options from the JSON files in this folder:
#   - noctalia.json        — main settings
#   - colors.json          — theme / palette
#   - screen-recorder.json — plugin settings
#
# The wallpaper path is patched into the JSON at evaluation time so it
# always points at this repo's assets/wallpapers/clouds.jpg, regardless of
# what was hard-coded into the original settings file.
#
{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, lib, ... }:
  let
    wallpaperPath = ../../../assets/wallpapers/clouds.jpg;
    # JSON parsing rejects strings with Nix store-path context; discard it.
    wallpaperPathString = builtins.unsafeDiscardStringContext "${wallpaperPath}";
    settingsJson =
      builtins.replaceStrings
        [ "/home/SunSD/Pictures/Wallpapers/clouds.jpg" ]
        [ wallpaperPathString ]
        (builtins.unsafeDiscardStringContext (builtins.readFile ./noctalia.json));
  in {
    home-manager.users.SunSD = { ... }: {
      imports = [ inputs.noctalia.homeModules.default ];

      # Make wallpapers available under ~/Pictures/Wallpapers.
      home.file."Pictures/Wallpapers" = {
        source = ../../../assets/wallpapers;
        recursive = true;
      };

      # Tell Noctalia which wallpaper to show by default.
      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = wallpaperPathString;
        wallpapers = {};
      };

      # ── Noctalia shell config ────────────────────────────────────────────
      # `package` is patched to hide the lockscreen header and to use our
      # wallpaper as the lockscreen background image.
      programs.noctalia-shell = {
        enable = true;
        package = lib.mkForce (
          inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
            postPatch = (old.postPatch or "") + ''
              if [ -f Modules/LockScreen/LockScreenHeader.qml ]; then
                sed -i '0,/Rectangle {/s|Rectangle {|Rectangle { visible: false;|' Modules/LockScreen/LockScreenHeader.qml
              fi
              if [ -f Modules/LockScreen/LockScreenBackground.qml ]; then
                sed -i 's|source: resolvedWallpaperPath|source: "file://${wallpaperPathString}"|' Modules/LockScreen/LockScreenBackground.qml
              fi
            '';
          })
        );
        settings = builtins.fromJSON settingsJson;
        colors = builtins.fromJSON (builtins.readFile ./colors.json);

        plugins = {
          sources = [{
            enabled = true;
            name    = "Noctalia Plugins";
            url     = "https://github.com/noctalia-dev/noctalia-plugins";
          }];
          states = {
            screen-recorder = {
              enabled   = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
            polkit-agent = {
              enabled   = true;
              sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
            };
          };
          version = 2;
        };

        pluginSettings.screen-recorder =
          builtins.fromJSON (builtins.readFile ./screen-recorder.json);
      };
    };
  };
}
