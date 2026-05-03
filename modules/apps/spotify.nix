{ ... }: {
  flake.nixosModules.spotify = { pkgs, lib, ... }: {
    home-manager.users.SunSD = { ... }:
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

        xdg.desktopEntries.spotify = {
          name = "Spotify";
          genericName = "Music Player";
          comment = "Spotify desktop client patched by SpotX-Bash when available";
          exec = "flatpak run com.spotify.Client %U";
          icon = "com.spotify.Client";
          terminal = false;
          type = "Application";
          categories = [ "Audio" "Music" "Player" "AudioVideo" ];
          mimeType = [ "x-scheme-handler/spotify" ];
        };

        home.activation.spotifySpotX = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          FLATPAK="${pkgs.flatpak}/bin/flatpak"

          if [ -x "$FLATPAK" ]; then
            "$FLATPAK" remote-add --user --if-not-exists flathub \
              https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true

            if ! "$FLATPAK" list --user --app --columns=application 2>/dev/null | grep -qx com.spotify.Client; then
              "$FLATPAK" install --user -y flathub com.spotify.Client >/dev/null 2>&1 || true
            fi

            if "$FLATPAK" list --user --app --columns=application 2>/dev/null | grep -qx com.spotify.Client; then
              ${spotx}/bin/spotx -fch >/dev/null 2>&1 || true
            fi
          fi
        '';
      };
  };
}
