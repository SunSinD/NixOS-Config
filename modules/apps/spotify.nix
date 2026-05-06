{ ... }: {
  flake.nixosModules.spotify = { pkgs, ... }: {
    home-manager.users.SunSD = { lib, ... }:
      let
        spotx = pkgs.writeShellApplication {
          name = "spotx";
          runtimeInputs = with pkgs; [
            bash
            curl
            perl
            unzip
            zip
          ];
          text = ''
            exec bash -c 'bash <(curl -sSL https://spotx-official.github.io/run.sh) "$@"' spotx "$@"
          '';
        };
      in {
        home.packages = [ spotx ];

        xdg.enable = true;

        home.file.".local/share/applications/spotx.desktop".text = ''
          [Desktop Entry]
          Name=Spotify
          GenericName=Music Player
          Comment=Spotify desktop client patched by SpotX-Bash
          Exec=flatpak run com.spotify.Client %U
          Icon=com.spotify.Client
          Terminal=false
          Type=Application
          Categories=Audio;Music;Player;AudioVideo;
          MimeType=x-scheme-handler/spotify;
        '';

        home.activation.spotifySpotX = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          FLATPAK="${pkgs.flatpak}/bin/flatpak"
          GTK_UPDATE_ICON_CACHE="${pkgs.gtk3}/bin/gtk-update-icon-cache"

          rm -f "$HOME/.local/share/applications/spotify.desktop"

          if [ -x "$FLATPAK" ]; then
            "$FLATPAK" remote-add --user --if-not-exists flathub \
              https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true

            if ! "$FLATPAK" list --user --app --columns=application 2>/dev/null | grep -qx com.spotify.Client; then
              "$FLATPAK" install --user -y flathub com.spotify.Client >/dev/null 2>&1 || true
            fi

            if "$FLATPAK" list --user --app --columns=application 2>/dev/null | grep -qx com.spotify.Client; then
              ${spotx}/bin/spotx -fch >/dev/null 2>&1 || true

              # Ensure the icon resolves for launchers (Noctalia) even if it fails to
              # pick up Flatpak export icons.
              ICON_SRC="$HOME/.local/share/flatpak/exports/share/icons/hicolor/256x256/apps/com.spotify.Client.png"
              ICON_DST_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
              if [ -f "$ICON_SRC" ]; then
                mkdir -p "$ICON_DST_DIR"
                cp -f "$ICON_SRC" "$ICON_DST_DIR/com.spotify.Client.png" >/dev/null 2>&1 || true
                [ -x "$GTK_UPDATE_ICON_CACHE" ] && "$GTK_UPDATE_ICON_CACHE" -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
              fi
            fi
          fi
        '';
      };
  };
}
