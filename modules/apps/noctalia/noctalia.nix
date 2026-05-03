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
            substituteInPlace Services/UI/WallpaperService.qml \
              --replace-fail 'readonly property string noctaliaDefaultWallpaper: Quickshell.shellDir + "/Assets/Wallpaper/noctalia.png"' 'readonly property string noctaliaDefaultWallpaper: "/home/SunSD/Pictures/Wallpapers/clouds.jpg"' \
              --replace-fail 'root.currentWallpapers = wallpaperCacheAdapter.wallpapers || {};' 'root.currentWallpapers = {};' \
              --replace-fail 'root.defaultWallpaper = wallpaperCacheAdapter.defaultWallpaper;' 'root.defaultWallpaper = root.noctaliaDefaultWallpaper;'
            substituteInPlace Modules/MainScreen/BarContentWindow.qml \
              --replace-fail 'property bool windowVisible: !isHidden' 'property bool windowVisible: !isHidden
  readonly property bool fadeHidden: isHidden || !BarService.effectivelyVisible' \
              --replace-fail 'visible: contentLoaded && windowVisible && BarService.effectivelyVisible' 'visible: contentLoaded && windowVisible' \
              --replace-fail 'if (barWindow.isHidden)
        barWindow.windowVisible = false;' 'if (barWindow.fadeHidden)
        barWindow.windowVisible = false;' \
              --replace-fail 'if (BarService.effectivelyVisible && !barWindow.isHidden && !barWindow.contentLoaded) {
        barWindow.contentLoaded = true;
      }' 'if (BarService.effectivelyVisible) {
        windowHideTimer.stop();
        barWindow.windowVisible = true;
        if (!barWindow.contentLoaded) {
          barWindow.contentLoaded = true;
        }
      } else {
        windowHideTimer.restart();
      }' \
              --replace-fail 'opacity: barWindow.isHidden ? 0 : 1' 'opacity: barWindow.fadeHidden ? 0 : 1' \
              --replace-fail 'enabled: barWindow.autoHide' 'enabled: true'
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
