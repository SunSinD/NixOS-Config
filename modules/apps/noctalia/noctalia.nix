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
            substituteInPlace Modules/LockScreen/LockScreenHeader.qml \
              --replace-fail 'width: Math.max(500, contentRow.implicitWidth + 32)' 'width: Math.max(260, contentRow.implicitWidth + 32)' \
              --replace-fail 'height: Math.max(120, contentRow.implicitHeight + 32)' 'height: Math.max(92, contentRow.implicitHeight + 24)' \
              --replace-fail 'anchors.topMargin: 100' 'anchors.topMargin: Math.round(parent.height * 0.18)' \
              --replace-fail 'color: Color.mSurface' 'color: "transparent"' \
              --replace-fail 'border.width: Style.borderS' 'border.width: 0' \
              --replace-fail 'showProgress: true' 'showProgress: false' \
              --replace-fail 'Layout.preferredWidth: Settings.data.general.clockStyle === "analog" ? 70 : (Settings.data.general.clockStyle === "custom" ? 90 : 70)' 'Layout.preferredWidth: Settings.data.general.clockStyle === "analog" ? 70 : (Settings.data.general.clockStyle === "custom" ? 190 : 70)' \
              --replace-fail 'Layout.preferredHeight: Settings.data.general.clockStyle === "analog" ? 70 : (Settings.data.general.clockStyle === "custom" ? 90 : 70)' 'Layout.preferredHeight: 76' \
              --replace-fail 'pointSize: Style.fontSizeL' 'pointSize: Style.fontSizeXXL'
            sed -i '/\/\/ Left side: Avatar/{n; s/Rectangle {/Rectangle {\
      visible: false/;}' Modules/LockScreen/LockScreenHeader.qml
            sed -i '/\/\/ Center: User Info Column/{n; s/ColumnLayout {/ColumnLayout {\
      visible: false\
      Layout.preferredWidth: 0/;}' Modules/LockScreen/LockScreenHeader.qml
            sed -i '/\/\/ Spacer to push time to the right/{n; n; s/Layout.fillWidth: true/Layout.preferredWidth: 0/;}' Modules/LockScreen/LockScreenHeader.qml
            substituteInPlace Modules/LockScreen/LockScreenPanel.qml \
              --replace-fail 'visible: Settings.data.general.compactLockScreen && (batteryIndicator.isReady || keyboardLayout.currentLayout !== "Unknown" || LockKeysService.capsLockOn)' 'visible: false'
            substituteInPlace Modules/Panels/Launcher/Providers/ApplicationsProvider.qml \
              --replace-fail 'return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId);' 'const normalizedName = normalizeAppId(app.name || "");
    const normalizedExec = normalizeAppId(getExecutableName(app));
    const defaultPinned = ["equibop", "spotx", "vivaldi", "zed", "zeditor"];
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
      return !isSpotifyEntry || isPreferredSpotify;
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
