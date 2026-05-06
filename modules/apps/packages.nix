{ ... }: {
  flake.nixosModules.packages = { pkgs, lib, ... }: {
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
          sunsd-focus-or-spawn =
            let
              jqFilter = pkgs.writeText "niri-focus-windows.jq"
                (builtins.replaceStrings [ "\r" ] [ "" ] (builtins.readFile ./niri-focus-windows.jq));
              jqExe = lib.getExe pkgs.jq;
              scriptBody = builtins.replaceStrings [ "@JQ@" "@FILTER@" ] [ jqExe "${jqFilter}" ]
                (builtins.replaceStrings [ "\r" ] [ "" ] (builtins.readFile ./sunsd-focus-or-spawn.sh));
            in
            pkgs.writeShellApplication {
              name = "sunsd-focus-or-spawn";
              runtimeInputs = with pkgs; [ jq ];
              text = scriptBody;
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
