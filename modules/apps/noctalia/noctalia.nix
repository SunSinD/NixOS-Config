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
            if [ -f Modules/Bar/Widgets/Workspace.qml ]; then
              sed -i 's|targetList.push(workspaceData);|if (workspaceData.idx <= 3) targetList.push(workspaceData);|g' Modules/Bar/Widgets/Workspace.qml
            fi
            if [ -f Modules/LockScreen/LockScreenHeader.qml ]; then
              sed -i '/\/\/ Left side: Avatar/{n; s|Rectangle {|Rectangle { visible: false; Layout.preferredWidth: 0; Layout.maximumWidth: 0|;}' Modules/LockScreen/LockScreenHeader.qml
              sed -i '/\/\/ Center: User Info Column/{n; s|ColumnLayout {|ColumnLayout { visible: false; Layout.preferredWidth: 0; Layout.maximumWidth: 0|;}' Modules/LockScreen/LockScreenHeader.qml
              sed -i '/\/\/ Spacer to push time to the right/{n; n; s|Layout.fillWidth: true|Layout.preferredWidth: 0|;}' Modules/LockScreen/LockScreenHeader.qml
              sed -i 's|width: Math.max(500, contentRow.implicitWidth + 32)|width: Math.max(260, contentRow.implicitWidth + 48)|g' Modules/LockScreen/LockScreenHeader.qml
              sed -i 's|pointSize: Style.fontSizeL|pointSize: Style.fontSizeXXL|g' Modules/LockScreen/LockScreenHeader.qml
            fi
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
