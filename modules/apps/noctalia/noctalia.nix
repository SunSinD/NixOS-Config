{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, lib, ... }: {
    let
      wallpaperPath = ../../../assets/wallpapers/clouds.jpg;
      wallpaperPathString = "${wallpaperPath}";
      settingsJson =
        builtins.replaceStrings
          [ "/home/SunSD/Pictures/Wallpapers/clouds.jpg" ]
          [ wallpaperPathString ]
          (builtins.readFile ./noctalia.json);
    in
    home-manager.users.SunSD = { ... }: {
      imports = [ inputs.noctalia.homeModules.default ];

      home.file."Pictures/Wallpapers" = {
        source = ../../../assets/wallpapers;
        recursive = true;
      };

      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = wallpaperPathString;
        wallpapers = {};
      };

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
