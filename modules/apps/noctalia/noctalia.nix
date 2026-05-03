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
              --replace-fail 'targetList.push(workspaceData);' 'if (workspaceData.idx <= 4) targetList.push(workspaceData);'
            substituteInPlace Services/UI/WallpaperService.qml \
              --replace-fail 'readonly property string noctaliaDefaultWallpaper: Quickshell.shellDir + "/Assets/Wallpaper/noctalia.png"' 'readonly property string noctaliaDefaultWallpaper: "/home/SunSD/Pictures/Wallpapers/clouds.jpg"' \
              --replace-fail 'root.currentWallpapers = wallpaperCacheAdapter.wallpapers || {};' 'root.currentWallpapers = {};' \
              --replace-fail 'root.defaultWallpaper = wallpaperCacheAdapter.defaultWallpaper;' 'root.defaultWallpaper = root.noctaliaDefaultWallpaper;'
            substituteInPlace Modules/LockScreen/LockScreenHeader.qml \
              --replace-fail 'showProgress: true' 'showProgress: false' \
              --replace-fail 'Layout.preferredWidth: Settings.data.general.clockStyle === "analog" ? 70 : (Settings.data.general.clockStyle === "custom" ? 90 : 70)' 'Layout.preferredWidth: Settings.data.general.clockStyle === "analog" ? 70 : (Settings.data.general.clockStyle === "custom" ? 160 : 70)' \
              --replace-fail 'Layout.preferredHeight: Settings.data.general.clockStyle === "analog" ? 70 : (Settings.data.general.clockStyle === "custom" ? 90 : 70)' 'Layout.preferredHeight: 70'
            substituteInPlace Modules/Panels/Launcher/Providers/ApplicationsProvider.qml \
              --replace-fail 'return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId);' 'const normalizedName = normalizeAppId(app.name || "");
    const normalizedExec = normalizeAppId(getExecutableName(app));
    const defaultPinned = ["vivaldi", "equibop", "spotify", "spotx", "zed", "zeditor"];
    return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId)
      || defaultPinned.some(pinnedId => normalizedId.includes(pinnedId) || normalizedName.includes(pinnedId) || normalizedExec.includes(pinnedId));' \
              --replace-fail 'showsCategories = true;' 'showsCategories = false;' \
              --replace-fail 'let filteredEntries = entries;' 'let filteredEntries = entries;
    if (!isSearching) {
      filteredEntries = entries.filter(app => isAppPinned(app));
    }'
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
