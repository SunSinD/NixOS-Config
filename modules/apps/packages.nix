{ ... }: {
  flake.nixosModules.packages = { pkgs, lib, ... }:
  let
    sunsd-terminal = pkgs.writeShellApplication {
      name = "sunsd-terminal";
      runtimeInputs = with pkgs; [ coreutils procps ghostty foot ];
      text = builtins.replaceStrings [ "\r" ] [ "" ] ''
        set -euo pipefail

        if command -v ghostty >/dev/null 2>&1; then
          # Some ghostty builds daemonize (parent exits quickly), which made
          # the old logic fall through to foot and open two terminals.
          exec ghostty "$@"
        fi

        exec foot "$@"
      '';
    };

    # NOTE: Don't use writeShellApplication here: it wraps PATH to runtimeInputs
    # only, which breaks when `noctalia-shell` is provided by Home Manager.
    sunsd-noctalia-launcher-toggle = pkgs.writeShellScriptBin "sunsd-noctalia-launcher-toggle" (
      builtins.replaceStrings [ "\r" ] [ "" ] ''
        set -euo pipefail

        export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/SunSD/bin''${HOME+:$HOME/.nix-profile/bin}:$PATH"

        # niri injects NOCTALIA_SETTINGS_FILE via its config environment block.
        export NOCTALIA_SETTINGS_FILE="''${NOCTALIA_SETTINGS_FILE:-}"

        if ! pgrep -x noctalia-shell >/dev/null 2>&1; then
          # Start Noctalia if it isn't running, then give it a moment to come up.
          ( nohup noctalia-shell >/tmp/noctalia-shell.log 2>&1 & ) || true
          sleep 0.4
        fi

        # If it's still not up, just exit quietly (so the hotkey doesn't block).
        pgrep -x noctalia-shell >/dev/null 2>&1 || exit 0

        noctalia-shell ipc call launcher toggle >/dev/null 2>&1 || true
      ''
    );

    sunsd-noctalia-ipc = pkgs.writeShellScriptBin "sunsd-noctalia-ipc" (
      builtins.replaceStrings [ "\r" ] [ "" ] ''
        set -euo pipefail

        # Usage: sunsd-noctalia-ipc <module> <method> [args...]
        [[ $# -ge 2 ]] || exit 0

        export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/SunSD/bin''${HOME+:$HOME/.nix-profile/bin}:$PATH"

        # niri injects NOCTALIA_SETTINGS_FILE via its config environment block.
        export NOCTALIA_SETTINGS_FILE="''${NOCTALIA_SETTINGS_FILE:-}"

        if ! pgrep -x noctalia-shell >/dev/null 2>&1; then
          ( nohup noctalia-shell >/tmp/noctalia-shell.log 2>&1 & ) || true
          sleep 0.4
        fi

        pgrep -x noctalia-shell >/dev/null 2>&1 || exit 0

        noctalia-shell ipc call "$1" "$2" "''${@:3}" >/dev/null 2>&1 || true
      ''
    );

    sunsd-session-ensure = pkgs.writeShellScriptBin "sunsd-session-ensure" (
      builtins.replaceStrings [ "\r" ] [ "" ] ''
        set -euo pipefail

        log="/tmp/sunsd-session-ensure.log"
        mkdir -p /tmp || true
        {
          echo "---- $(date -Is) ----"
          echo "argv: $*"
          echo "uid: $(id -u) user: $(id -un) home: ${HOME:-<unset>}"
        } >>"$log" 2>&1 || true

        export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/SunSD/bin''${HOME+:$HOME/.nix-profile/bin}:$PATH"

        # niri injects these via its config `environment { ... }` block.
        WALLPAPER_PATH="''${WALLPAPER_PATH:-}"
        NOCTALIA_SETTINGS_FILE="''${NOCTALIA_SETTINGS_FILE:-}"
        echo "PATH=$PATH" >>"$log" 2>&1 || true
        echo "WALLPAPER_PATH=$WALLPAPER_PATH" >>"$log" 2>&1 || true
        echo "NOCTALIA_SETTINGS_FILE=$NOCTALIA_SETTINGS_FILE" >>"$log" 2>&1 || true

        noctalia_bin="$(command -v noctalia-shell 2>/dev/null || true)"
        swaybg_bin="$(command -v swaybg 2>/dev/null || true)"
        echo "noctalia-shell=$(printf %s "$noctalia_bin")" >>"$log" 2>&1 || true
        echo "swaybg=$(printf %s "$swaybg_bin")" >>"$log" 2>&1 || true

        ensure_wallpaper() {
          [[ -n "$WALLPAPER_PATH" ]] || return 0
          if ! pgrep -x swaybg >/dev/null 2>&1; then
            [[ -n "$swaybg_bin" ]] || { echo "swaybg not found" >>"$log" 2>&1; return 0; }
            ( nohup "$swaybg_bin" -m fill -i "$WALLPAPER_PATH" >/tmp/swaybg.log 2>&1 & ) || true
            sleep 0.15
          fi
        }

        ensure_noctalia() {
          export NOCTALIA_SETTINGS_FILE="$NOCTALIA_SETTINGS_FILE"
          if ! pgrep -x noctalia-shell >/dev/null 2>&1; then
            [[ -n "$noctalia_bin" ]] || { echo "noctalia-shell not found" >>"$log" 2>&1; return 0; }
            ( nohup "$noctalia_bin" >/tmp/noctalia-shell.log 2>&1 & ) || true
            sleep 0.4
          fi
        }

        case "''${1:-}" in
          startup)
            ensure_wallpaper
            ensure_noctalia
            ;;
          ipc)
            shift || true
            ensure_noctalia
            if ! pgrep -x noctalia-shell >/dev/null 2>&1; then
              echo "noctalia-shell still not running; skipping ipc" >>"$log" 2>&1 || true
              exit 0
            fi
            [[ $# -ge 2 ]] || exit 0
            echo "ipc: $1 $2 ''${*:3}" >>"$log" 2>&1 || true
            "$noctalia_bin" ipc call "$1" "$2" "''${@:3}" >>"$log" 2>&1 || true
            ;;
          *)
            # default: just ensure both
            ensure_wallpaper
            ensure_noctalia
            ;;
        esac

        echo "done" >>"$log" 2>&1 || true
      ''
    );

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
  in {
    environment.systemPackages =
      [
        sunsd-terminal
        sunsd-noctalia-launcher-toggle
        sunsd-noctalia-ipc
        sunsd-session-ensure
        sunsd-focus-or-spawn
      ]
      ++ (with pkgs; [
        grim
        slurp
        wl-clipboard
        libnotify
        imagemagick
        (tesseract.override { enableLanguages = [ "eng" ]; })
        mpv
        foot
        ghostty
        vivaldi
        thunar
        zed-editor
        swaybg
        xwayland-satellite
      ]);

    home-manager.users.SunSD = { pkgs, ... }: {
      home.packages =
        (with pkgs; [
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

          adwaita-icon-theme
          gnome-themes-extra
          hicolor-icon-theme
          papirus-icon-theme
          dconf
          bibata-cursors

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
