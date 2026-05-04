{ inputs, ... }: {
  flake.nixosModules.noctalia = { pkgs, lib, ... }: {
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
        package = lib.mkForce (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace Modules/Bar/Widgets/Workspace.qml \
              --replace-fail 'targetList.push(workspaceData);' 'if (workspaceData.idx <= 3) targetList.push(workspaceData);'
            substituteInPlace Services/UI/WallpaperService.qml \
              --replace-fail 'readonly property string noctaliaDefaultWallpaper: Quickshell.shellDir + "/Assets/Wallpaper/noctalia.png"' 'readonly property string noctaliaDefaultWallpaper: "/home/SunSD/Pictures/Wallpapers/clouds.jpg"' \
              --replace-fail 'root.currentWallpapers = wallpaperCacheAdapter.wallpapers || {};' 'root.currentWallpapers = {};' \
              --replace-fail 'root.defaultWallpaper = wallpaperCacheAdapter.defaultWallpaper;' 'root.defaultWallpaper = root.noctaliaDefaultWallpaper;'
            if [ -f Modules/LockScreen/LockScreenHeader.qml ]; then
              sed -i 's|pointSize: Style.fontSizeL|pointSize: Style.fontSizeXXL|g; s|color: Color.mSurface|color: "transparent"|g; s|border.width: Style.borderS|border.width: 0|g; s|width: Math.max(500, contentRow.implicitWidth + 32)|width: Math.max(320, contentRow.implicitWidth + 32)|g; s|height: Math.max(120, contentRow.implicitHeight + 32)|height: Math.max(110, contentRow.implicitHeight + 28)|g' Modules/LockScreen/LockScreenHeader.qml
            fi
            if [ -f Modules/LockScreen/LockScreenPanel.qml ]; then
              sed -i 's|visible: Settings.data.general.compactLockScreen && (batteryIndicator.isReady || keyboardLayout.currentLayout !== "Unknown" || LockKeysService.capsLockOn)|visible: false|g' Modules/LockScreen/LockScreenPanel.qml
            fi
            substituteInPlace Modules/Panels/Launcher/Providers/ApplicationsProvider.qml \
              --replace-fail 'return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId);' 'const normalizedName = normalizeAppId(app.name || "");
    const normalizedExec = normalizeAppId(getExecutableName(app));
    const defaultPinned = ["equibop", "spotx", "steam", "google-chrome-fresh", "vivaldi", "zed", "zeditor"];
    return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId)
      || defaultPinned.some(pinnedId => normalizedId.includes(pinnedId) || normalizedName.includes(pinnedId) || normalizedExec.includes(pinnedId));' \
              --replace-fail 'showsCategories = true;' 'showsCategories = false;' \
              --replace-fail 'let filteredEntries = entries;' 'let filteredEntries = entries;
    filteredEntries = filteredEntries.filter(app => {
      const normalizedId = normalizeAppId(app.id || app.desktopId || "");
      const normalizedName = normalizeAppId(app.name || "");
      const normalizedExec = normalizeAppId(getExecutableName(app));
      const isSpotifyEntry = normalizedId.includes("spotify")
        || normalizedName === "spotify"
        || normalizedExec.includes("spotify");
      const isPreferredSpotify = normalizedId.includes("spotx")
        || normalizedExec.includes("spotx");
      const isChromeEntry = normalizedId.includes("google-chrome")
        || normalizedName === "google chrome"
        || normalizedExec.includes("google-chrome");
      const isPreferredChrome = normalizedId.includes("google-chrome-fresh");
      return (!isSpotifyEntry || isPreferredSpotify)
        && (!isChromeEntry || isPreferredChrome);
    });
    if (!isSearching) {
      filteredEntries = filteredEntries.filter(app => isAppPinned(app));
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
