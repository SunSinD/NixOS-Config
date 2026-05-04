{ ... }: {
  flake.nixosModules.steam = { pkgs, ... }: {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };

    hardware.steam-hardware.enable = true;

    home-manager.users.SunSD = { ... }: {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "steam-niri";
          runtimeInputs = [ pkgs.steam ];
          text = ''
            export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"
            export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:-niri}"
            exec steam "$@"
          '';
        })
      ];

      home.file = {
        ".local/share/applications/steam.desktop".text = ''
          [Desktop Entry]
          Name=Steam
          GenericName=Game Launcher
          Comment=Launch Steam
          Exec=steam-niri %U
          Icon=${pkgs.steam}/share/icons/hicolor/256x256/apps/steam.png
          Terminal=false
          Type=Application
          Categories=Network;FileTransfer;Game;
          MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
        '';
      };
    };
  };
}
