#
# files.nix
# ─────────
# Two responsibilities:
#
#   1. Define the user's home folder layout (XDG user directories under
#      ~/Files/, plus empty .keep files so the subfolders exist).
#
#   2. Override .desktop entries for installed apps: most are hidden
#      (`NoDisplay=true`) so they don't clutter the launcher (Noctalia +
#      fuzzel), and a custom Chrome entry launches a clean dark profile.
#
{ ... }: {
  flake.nixosModules.files = { pkgs, lib, ... }: {
    home-manager.users.SunSD = { config, ... }:
    let
      # Hidden with a small stub entry. Fine for apps we never open files
      # or links with (the stub has no Exec line).
      hiddenStubs = [
        "google-chrome"
        "google-chrome-stable"
        "btop"
        "btop++"
        "blueman-adapters"
        "blueman-manager"
        "thunar-bulk-rename"
        "thunar-settings"
        "nvim"
        "ghostty"
        "com.mitchellh.ghostty"
        "md.obsidian.Obsidian"
        "nixos-manual"
        "remote-viewer"
        "virt-manager"
        "pavucontrol"
        "org.pulseaudio.pavucontrol"
        "com.spotify.Client"
        "com.obsproject.Studio"
        "foot"
        "footclient"
        "foot-server"
      ];

      # Hidden but still working: a copy of the app's real entry with
      # NoDisplay=true added. Needed for apps that open folders, files or
      # links (e.g. Thunar is the default for folders), because a stub
      # without Exec would break "open with".
      hiddenCopies = {
        thunar   = pkgs.thunar;
        mpv      = pkgs.mpv;
        obsidian = pkgs.obsidian;
      };

      stub = name: {
        name  = ".local/share/applications/${name}.desktop";
        value.text = ''
          [Desktop Entry]
          Name=${name}
          Type=Application
          NoDisplay=true
        '';
      };

      hiddenCopy = name: pkg: {
        name  = ".local/share/applications/${name}.desktop";
        value.source = pkgs.runCommand "${name}-hidden.desktop" { } ''
          sed -e '/^NoDisplay=/d' -e '/^\[Desktop Entry\]$/a NoDisplay=true' \
            ${pkg}/share/applications/${name}.desktop > $out
        '';
      };
    in {
      # ── XDG user directories ──────────────────────────────────────────────
      # Point Downloads + Documents into ~/Files (a single tidy hub).
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
        # Hide the nixconf checkout from the file manager listings.
        ".hidden".text = ''
          nixconf
          NixOS-Config
        '';

        "Files/.hidden".text = ''
          nixconf
          NixOS-Config
        '';

        # ── Folder placeholders ────────────────────────────────────────────
        # Empty `.keep` files so `~/Files/...` subfolders always exist.
        "Files/Downloads/.keep".text = "";
        "Files/Games/Co-op Games/.keep".text = "";
        "Files/Games/Solo Games/.keep".text = "";
        "Files/Others/.keep".text = "";

        # ── Custom Chrome launcher ────────────────────────────────────────
        # Opens a dedicated profile with dark mode forced on and no first-run
        # prompts. Useful as a clean second browser alongside Vivaldi.
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
      }
      # ── Hidden launcher entries ─────────────────────────────────────────
      // lib.listToAttrs (map stub hiddenStubs)
      // lib.mapAttrs' hiddenCopy hiddenCopies;
    };
  };
}
