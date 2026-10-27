#
# packages.nix
# ────────────
# Two things live here:
#
#   1. Small "sunsd-*" helper scripts wrapped as Nix packages so they end up
#      on PATH like any other binary (sunsd-terminal, sunsd-session-ensure,
#      sunsd-focus-or-spawn). These are what the niri keybindings call.
#
#   2. The actual list of programs installed system-wide
#      (`environment.systemPackages`) and per-user via Home Manager
#      (`home.packages`). Anything niri calls by full path
#      (/run/current-system/sw/bin/...) must be in systemPackages.
#
{ ... }: {
  flake.nixosModules.packages = { pkgs, lib, ... }:
  let
    # Strip Windows line endings in case a file was saved with CRLF.
    stripCR = builtins.replaceStrings [ "\r" ] [ "" ];

    tesseract = pkgs.tesseract.override { enableLanguages = [ "eng" ]; };

    # sunsd-terminal: opens a foot terminal instantly. Tries the foot SERVER
    # first (footclient is near-instant) and falls back to a fresh `foot`.
    # --no-wait: return as soon as the window opens, so closing the window
    # later can't trigger the fallback and open a second terminal.
    sunsd-terminal = pkgs.writeShellApplication {
      name = "sunsd-terminal";
      runtimeInputs = [ pkgs.foot ];
      text = stripCR ''
        if footclient --no-wait "$@" >/dev/null 2>&1; then
          exit 0
        fi

        exec foot "$@"
      '';
    };

    # sunsd-session-ensure: makes sure the wallpaper (swaybg) and the
    # Noctalia shell are running, and forwards IPC calls to Noctalia.
    #   sunsd-session-ensure startup                 start both
    #   sunsd-session-ensure ipc <module> <method>   call Noctalia IPC
    # Logs to /tmp/sunsd-session-ensure.log.
    # Not writeShellApplication: it would limit PATH to runtimeInputs, but
    # noctalia-shell comes from Home Manager.
    sunsd-session-ensure = pkgs.writeShellScriptBin "sunsd-session-ensure" (stripCR ''
      set -euo pipefail

      log="/tmp/sunsd-session-ensure.log"
      {
        echo "---- $(date -Is) ----"
        echo "argv: $*"
      } >>"$log" 2>&1 || true

      export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/SunSD/bin''${HOME+:$HOME/.nix-profile/bin}:$PATH"

      # niri injects these via its config `environment { ... }` block.
      WALLPAPER_PATH="''${WALLPAPER_PATH:-}"
      export NOCTALIA_SETTINGS_FILE="''${NOCTALIA_SETTINGS_FILE:-}"

      noctalia_bin="$(command -v noctalia-shell 2>/dev/null || true)"
      swaybg_bin="$(command -v swaybg 2>/dev/null || true)"

      noctalia_ipc() {
        [[ -n "$noctalia_bin" ]] || return 127
        "$noctalia_bin" ipc call "$1" "$2" "''${@:3}" >>"$log" 2>&1
      }

      ensure_wallpaper() {
        [[ -n "$WALLPAPER_PATH" ]] || return 0
        pgrep -x swaybg >/dev/null 2>&1 && return 0
        [[ -n "$swaybg_bin" ]] || { echo "swaybg not found" >>"$log" 2>&1; return 0; }
        ( nohup "$swaybg_bin" -m fill -i "$WALLPAPER_PATH" >/tmp/swaybg.log 2>&1 & ) || true
        sleep 0.15
      }

      ensure_noctalia() {
        [[ -n "$noctalia_bin" ]] || { echo "noctalia-shell not found" >>"$log" 2>&1; return 0; }

        # If IPC responds, Noctalia is already up.
        noctalia_ipc state all >/dev/null 2>&1 && return 0

        # Start Noctalia and wait (up to ~6s) for IPC to respond.
        ( nohup "$noctalia_bin" >/tmp/noctalia-shell.log 2>&1 & ) || true
        for _ in $(seq 1 30); do
          if noctalia_ipc state all >/dev/null 2>&1; then
            echo "noctalia ipc ready" >>"$log" 2>&1 || true
            return 0
          fi
          sleep 0.2
        done

        echo "noctalia ipc not ready after wait" >>"$log" 2>&1 || true
      }

      case "''${1:-}" in
        ipc)
          shift
          ensure_noctalia
          [[ $# -ge 2 ]] || exit 0
          noctalia_ipc "$1" "$2" "''${@:3}" || true
          ;;
        *)
          ensure_wallpaper
          ensure_noctalia
          ;;
      esac
    '');

    # sunsd-focus-or-spawn <regex> <command...>: focus the newest window whose
    # app-id/title matches <regex>, or run <command> if there is none.
    sunsd-focus-or-spawn =
      let
        jqFilter = pkgs.writeText "niri-focus-windows.jq" (stripCR (builtins.readFile ./focus-or-spawn/windows.jq));
      in
      pkgs.writeShellApplication {
        name = "sunsd-focus-or-spawn";
        runtimeInputs = [ pkgs.jq ];
        text = builtins.replaceStrings [ "@JQ@" "@FILTER@" ] [ (lib.getExe pkgs.jq) "${jqFilter}" ]
          (stripCR (builtins.readFile ./focus-or-spawn/focus-or-spawn.sh));
      };
  in {
    environment.systemPackages =
      [
        sunsd-terminal
        sunsd-session-ensure
        sunsd-focus-or-spawn
        tesseract
      ]
      ++ (with pkgs; [
        grim
        slurp
        wl-clipboard
        libnotify
        imagemagick
        mpv
        foot
        vivaldi
        thunar
        zed-editor
        swaybg
        xwayland-satellite
      ]);

    home-manager.users.SunSD = { pkgs, ... }: {
      programs.foot = {
        enable = true;
        # Use the actual font family name so foot doesn't fall back to
        # DejaVu Sans (which causes spacing issues).
        settings.main.font = "JetBrains Mono:size=14";
      };

      home.packages = with pkgs; [
        # CLI tools
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
        codex

        # Themes, icons, cursors
        adwaita-icon-theme
        gnome-themes-extra
        hicolor-icon-theme
        papirus-icon-theme
        dconf
        bibata-cursors

        # Virtual machines (libvirtd itself is only enabled on main-pc)
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        virtio-win
        win-spice

        # Apps
        google-chrome
        obs-studio
        gpu-screen-recorder
        obsidian
        pavucontrol
        moonlight-qt
        fuzzel
      ];

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
