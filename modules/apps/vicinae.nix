{ ... }: {
  flake.nixosModules.vicinae = { pkgs, ... }: {
    home-manager.users.SunSD = { config, ... }: {
      home.packages = with pkgs; [
        vicinae
      ];

      xdg.configFile."vicinae/nix.json".text = builtins.toJSON {
        close_on_focus_loss = true;
        consider_preedit = true;
        pop_to_root_on_close = true;
        favicon_service = "none";
        search_files_in_root = false;
        font = {
          rendering = "native";
          normal = {
            family = "Inter";
            size = 11.5;
          };
        };
        theme = {
          light = {
            name = "sunsd-graphite";
            icon_theme = "default";
          };
          dark = {
            name = "sunsd-graphite";
            icon_theme = "default";
          };
        };
        favorites = [
          "applications:equibop"
          "applications:spotx"
          "applications:vivaldi-stable"
          "applications:dev.zed.Zed"
          "@vicinae/clipboard:history"
          "@vicinae/core:search-emojis"
        ];
        launcher_window = {
          opacity = 0.92;
          client_side_decorations = {
            enabled = true;
            rounding = 14;
            border_width = 1;
          };
          size = {
            width = 820;
            height = 520;
          };
          layer_shell = {
            scope = "vicinae";
            keyboard_interactivity = "exclusive";
            layer = "overlay";
            enabled = true;
          };
        };
      };

      xdg.dataFile."vicinae/themes/sunsd-graphite.toml".text = ''
        [meta]
        version = 1
        name = "SunSD Graphite"
        description = "Clean dark grayscale desktop theme."
        variant = "dark"
        inherits = "vicinae-dark"

        [colors.core]
        background = "#101012"
        foreground = "#f4f4f5"
        secondary_background = "#1a1a1d"
        border = "#34343a"
        accent = "#f5f5f5"
        accent_foreground = "#0b0b0d"

        [colors.accents]
        blue = "#d4d4d8"
        green = "#d4d4d8"
        magenta = "#d4d4d8"
        orange = "#d4d4d8"
        purple = "#d4d4d8"
        red = "#ff6b6b"
        yellow = "#e4e4e7"
        cyan = "#e4e4e7"
      '';

      systemd.user.services.vicinae = {
        Unit = {
          Description = "Vicinae launcher daemon";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Environment = [
            "USE_LAYER_SHELL=1"
            "QT_QPA_PLATFORM=wayland"
            "QT_QUICK_FLICKABLE_WHEEL_DECELERATION=5000"
            "VICINAE_OVERRIDES=${config.xdg.configHome}/vicinae/nix.json"
          ];
          ExecStart = "${pkgs.vicinae}/bin/vicinae server";
          Restart = "always";
          RestartSec = 2;
          KillMode = "process";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
