{ ... }: {
  flake.nixosModules.packages = { pkgs, ... }: {
    home-manager.users.SunSD = { pkgs, ... }: {
      home.packages =
        let
          sunsd-terminal = pkgs.writeShellApplication {
            name = "sunsd-terminal";
            runtimeInputs = with pkgs; [ coreutils procps ghostty foot ];
            text = builtins.replaceStrings [ "\r" ] [ "" ] ''
              set -euo pipefail

              # Prefer Ghostty, but in some VMs it exits instantly (renderer/GPU).
              if command -v ghostty >/dev/null 2>&1; then
                ghostty "$@" &
                pid=$!
                sleep 0.35
                if kill -0 "$pid" >/dev/null 2>&1; then
                  wait "$pid"
                  exit $?
                fi
              fi

              exec foot "$@"
            '';
          };
          sunsd-focus-or-spawn = pkgs.writeShellApplication {
            name = "sunsd-focus-or-spawn";
            runtimeInputs = with pkgs; [ jq ];
            # In Nix indented strings, every literal `$` for the shell/jq must be written as `''$`
            # or Nix mangles the script (broken quotes / missing `fi`).
            text = ''
              set -euo pipefail
              niri_bin=/run/current-system/sw/bin/niri
              if [[ ! -x ''$niri_bin ]]; then
                niri_bin=''$(command -v niri 2>/dev/null || true)
              fi
              [[ -n ''$niri_bin ]] || { echo "niri not found" >&2; exit 1; }
              pattern=''${1?}
              shift
              id=''$( "''$niri_bin" msg --json windows | ${pkgs.jq}/bin/jq -r --arg p "''$pattern" '
                [.Ok.Windows[]? | select(.app_id != null and (.app_id | test(''$p)))] | sort_by(.id) | .[-1].id // empty
              ')
              if [[ -n ''$id && ''$id != "null" ]]; then
                exec "''$niri_bin" msg action focus-window "''$id"
              else
                exec "''$@"
              fi
            '';
          };
        in
        (with pkgs; [
        # ── CLI tools ──────────────────────────────────────────────────────────
        neovim
        curl
        jq
        cliphist
        lstr
        bat
        fastfetch
        btop
        zip
        unzip
        wget

        # ── Theming ────────────────────────────────────────────────────────────
        adwaita-icon-theme
        gnome-themes-extra
        hicolor-icon-theme
        papirus-icon-theme
        dconf
        bibata-cursors

        # ── Virtualisation ─────────────────────────────────────────────────────
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        virtio-win
        win-spice

        vivaldi
        google-chrome
        obs-studio
        gpu-screen-recorder
        obsidian
        mpv
        thunar
        codex
        pavucontrol
        xwayland-satellite
        foot
        moonlight-qt

        # ── Screenshot / OCR / Pin ─────────────────────────────────────────────
        grim
        slurp
        wl-clipboard
        (tesseract.override { enableLanguages = [ "eng" ]; })
        imagemagick
        libnotify
        fuzzel
        swaybg
        ]) ++ [ sunsd-terminal sunsd-focus-or-spawn ];

      gtk = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      dconf = {
        enable = true;
        settings."org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
      };
    };
  };
}
