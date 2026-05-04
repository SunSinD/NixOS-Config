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
          Exec=obs-studio
          Icon=obs-studio-clean
          Terminal=false
          Type=Application
          Categories=AudioVideo;Recorder;
        '';

        ".local/share/icons/hicolor/scalable/apps/obs-studio-clean.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <rect width="128" height="128" rx="18" fill="#101014"/>
            <g fill="#e8e8e8">
              <path d="M65 21c15 9 22 24 19 42-9-8-21-11-36-8 0-15 6-27 17-34z"/>
              <path d="M101 73c-12 13-28 17-46 11 11-8 18-19 19-34 14 5 23 13 27 23z"/>
              <path d="M28 88c-3-17 4-32 20-43-1 14 5 26 17 36-12 8-25 10-37 7z"/>
            </g>
          </svg>
        '';
      };
    };
  };
}
