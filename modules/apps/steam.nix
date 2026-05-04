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
            export DISPLAY="''${DISPLAY:-:0}"
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
          Icon=steam-clean
          Terminal=false
          Type=Application
          Categories=Network;FileTransfer;Game;
          MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
        '';

        ".local/share/applications/com.obsproject.Studio.desktop".text = ''
          [Desktop Entry]
          Name=OBS Studio
          GenericName=Streaming/Recording Software
          Comment=Free and Open Source Streaming/Recording Software
          Exec=obs
          Icon=obs-clean
          Terminal=false
          Type=Application
          Categories=AudioVideo;Recorder;
        '';

        ".local/share/icons/hicolor/scalable/apps/steam-clean.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <rect width="128" height="128" rx="28" fill="#111214"/>
            <circle cx="83" cy="45" r="25" fill="none" stroke="#f5f5f5" stroke-width="9"/>
            <circle cx="83" cy="45" r="10" fill="#f5f5f5"/>
            <circle cx="43" cy="78" r="18" fill="none" stroke="#f5f5f5" stroke-width="9"/>
            <path d="M57 70l18-14" fill="none" stroke="#f5f5f5" stroke-width="10" stroke-linecap="round"/>
            <path d="M29 71l-14-6" fill="none" stroke="#f5f5f5" stroke-width="10" stroke-linecap="round"/>
          </svg>
        '';

        ".local/share/icons/hicolor/scalable/apps/obs-clean.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <rect width="128" height="128" rx="28" fill="#111214"/>
            <circle cx="64" cy="64" r="48" fill="#f5f5f5"/>
            <path d="M63 22c16 6 24 19 22 37-10-8-21-10-34-5 0-14 4-25 12-32z" fill="#111214"/>
            <path d="M101 72c-12 12-27 15-43 8 10-7 16-17 17-31 13 7 22 14 26 23z" fill="#111214"/>
            <path d="M29 86c-3-16 4-30 21-41-1 13 4 23 15 32-12 7-24 10-36 9z" fill="#111214"/>
          </svg>
        '';
      };
    };
  };
}
