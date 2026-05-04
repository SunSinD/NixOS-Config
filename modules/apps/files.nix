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
          Icon=obs-studio-clean
          Terminal=false
          Type=Application
          Categories=AudioVideo;Recorder;
        '';

        ".local/share/icons/hicolor/scalable/apps/obs-studio-clean.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <rect width="128" height="128" rx="18" fill="#101014"/>
            <g fill="#f5f5f5">
              <path d="M63 18c18 7 29 23 29 43-11-10-25-13-41-7 0-16 4-28 12-36z"/>
              <path d="M104 72c-13 16-32 21-51 14 12-8 20-21 21-37 15 7 25 15 30 23z"/>
              <path d="M27 91c-6-20 1-38 21-50-2 15 4 29 18 39-13 9-26 13-39 11z"/>
            </g>
          </svg>
        '';
      };
    };
  };
}
