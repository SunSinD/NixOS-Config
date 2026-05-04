{ inputs, ... }: {
  flake.nixosModules.noctalia = { ... }: {
    home-manager.users.SunSD = { ... }: {
      imports = [ inputs.noctalia.homeModules.default ];

      home.file."Pictures/Wallpapers" = {
        source = ../../../assets/wallpapers;
        recursive = true;
      };

      home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
        defaultWallpaper = "/home/SunSD/Pictures/Wallpapers/clouds.jpg";
        wallpapers = {};
      };

      programs.noctalia-shell = {
        enable   = true;
        settings = builtins.fromJSON (builtins.readFile ./noctalia.json);
        colors   = builtins.fromJSON (builtins.readFile ./colors.json);

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
