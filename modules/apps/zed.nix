{ ... }: {
  flake.nixosModules.zed = { ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.zed-editor = {
        enable = true;

        extensions = [ "html" "git-firefly" "nix" "kdl" ];

        userSettings = {
          project_panel.button     = true;
          bottom_dock_layout       = "contained";
          collaboration_panel.dock = "left";
          toolbar.quick_actions    = true;

          telemetry = {
            diagnostics = false;
            metrics     = false;
          };

          session.trust_all_worktrees = true;

          ui_font_size     = 16;
          buffer_font_size = 15;
          theme            = "Noctalia Dark Transparent";
        };
      };
    };
  };
}
