{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, lib, ... }: {
    home-manager.users.SunSD = { ... }: {
      imports = [ inputs.noctalia.homeModules.default ];

      home.file."Pictures/Wallpapers/clouds.jpg".source =
        ../../../assets/wallpapers/clouds.jpg;

      programs.noctalia-shell = {
        enable   = true;
        package = lib.mkForce (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace Modules/Bar/Widgets/Workspace.qml \
              --replace-fail 'targetList.push(workspaceData);' 'if (workspaceData.idx <= 3) targetList.push(workspaceData);'
            substituteInPlace Modules/Bar/Widgets/Clock.qml \
              --replace-fail 'return barFontSize;' 'return Math.round(barFontSize * 1.12);' \
              --replace-fail 'applyUiScale: false
              color: textColor' 'applyUiScale: false
              font.weight: Font.Bold
              color: textColor'
          '';
        }));
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
