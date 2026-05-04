{ ... }: {
  flake.nixosModules.files = { ... }: {
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
          Name=Google Chrome
          GenericName=Web Browser
          Comment=Clean dark Chrome profile
          Exec=google-chrome-stable --password-store=basic --force-dark-mode --enable-features=WebUIDarkMode --no-first-run --no-default-browser-check --disable-sync --disable-features=SignInProfileCreationFlow,ChromeWhatsNewUI --user-data-dir=/home/SunSD/.local/share/google-chrome-fresh about:blank
          Icon=google-chrome
          Terminal=false
          Type=Application
          Categories=Network;WebBrowser;
          StartupNotify=true
        '';
      };
    };
  };
}
