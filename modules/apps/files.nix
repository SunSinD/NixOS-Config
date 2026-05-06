{ ... }: {
  flake.nixosModules.files = { pkgs, ... }: {
    home-manager.users.SunSD = { config, ... }: {
      xdg = {
        enable = true;
        userDirs = {
          enable = true;
          createDirectories = true;
          download = "${config.home.homeDirectory}/Files/Downloads";
          documents = "${config.home.homeDirectory}/Files";
        };
      };

      home.file = {
        ".hidden".text = ''
          nixconf
          NixOS-Config
        '';

        "Files/.hidden".text = ''
          nixconf
          NixOS-Config
        '';

        "Files/Downloads/.keep".text = "";
        "Files/Games/Co-op Games/.keep".text = "";
        "Files/Games/Solo Games/.keep".text = "";
        "Files/Others/.keep".text = "";

        ".local/share/applications/google-chrome-fresh.desktop".text = ''
          [Desktop Entry]
          Name=Chrome
          GenericName=Web Browser
          Comment=Clean dark Chrome profile
          Exec=google-chrome-stable --password-store=basic --force-dark-mode --enable-features=WebUIDarkMode,ForceDark --no-first-run --no-default-browser-check --disable-sync --disable-features=SignInProfileCreationFlow,ChromeWhatsNewUI --user-data-dir=/home/SunSD/.local/share/google-chrome-fresh chrome://newtab/
          Icon=google-chrome
          Terminal=false
          Type=Application
          Categories=Network;WebBrowser;
          StartupNotify=true
        '';

        ".local/share/applications/google-chrome.desktop".text = ''
          [Desktop Entry]
          Name=Google Chrome
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/google-chrome-stable.desktop".text = ''
          [Desktop Entry]
          Name=Google Chrome
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/btop.desktop".text = ''
          [Desktop Entry]
          Name=btop
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/btop++.desktop".text = ''
          [Desktop Entry]
          Name=btop++
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/blueman-adapters.desktop".text = ''
          [Desktop Entry]
          Name=Bluetooth Adapters
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/blueman-manager.desktop".text = ''
          [Desktop Entry]
          Name=Bluetooth Manager
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/thunar-bulk-rename.desktop".text = ''
          [Desktop Entry]
          Name=Bulk Rename
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/nvim.desktop".text = ''
          [Desktop Entry]
          Name=Neovim
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/nirimod.desktop".text = ''
          [Desktop Entry]
          Name=NiriMod
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/nirimod-bin.desktop".text = ''
          [Desktop Entry]
          Name=NiriMod
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/ghostty.desktop".text = ''
          [Desktop Entry]
          Name=Ghostty
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/com.mitchellh.ghostty.desktop".text = ''
          [Desktop Entry]
          Name=Ghostty
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/obsidian.desktop".text = ''
          [Desktop Entry]
          Name=Obsidian
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/md.obsidian.Obsidian.desktop".text = ''
          [Desktop Entry]
          Name=Obsidian
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/nixos-manual.desktop".text = ''
          [Desktop Entry]
          Name=NixOS Manual
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/mpv.desktop".text = ''
          [Desktop Entry]
          Name=mpv Media Player
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/remote-viewer.desktop".text = ''
          [Desktop Entry]
          Name=Remote Viewer
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/thunar.desktop".text = ''
          [Desktop Entry]
          Name=Thunar File Manager
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/thunar-settings.desktop".text = ''
          [Desktop Entry]
          Name=Thunar Preferences
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/virt-manager.desktop".text = ''
          [Desktop Entry]
          Name=Virtual Machine Manager
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/pavucontrol.desktop".text = ''
          [Desktop Entry]
          Name=Volume Control
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/org.pulseaudio.pavucontrol.desktop".text = ''
          [Desktop Entry]
          Name=Volume Control
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/com.spotify.Client.desktop".text = ''
          [Desktop Entry]
          Name=Spotify
          Type=Application
          NoDisplay=true
        '';

        ".local/share/applications/com.obsproject.Studio.desktop".text = ''
          [Desktop Entry]
          Name=OBS Studio
          GenericName=Streaming/Recording Software
          Comment=Free and Open Source Streaming/Recording Software
          Exec=obs
          Icon=${pkgs.obs-studio}/share/icons/hicolor/256x256/apps/com.obsproject.Studio.png
          Terminal=false
          Type=Application
          Categories=AudioVideo;Recorder;
        '';

        ".local/share/applications/moonlight-qt.desktop".text = ''
          [Desktop Entry]
          Name=Moonlight
          GenericName=Game Streaming Client
          Comment=Play your PC games on almost any device
          Exec=moonlight
          Icon=${pkgs.moonlight-qt}/share/icons/hicolor/256x256/apps/moonlight.png
          Terminal=false
          Type=Application
          Categories=Game;Network;
        '';
      };
    };
  };
}
