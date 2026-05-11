#
# zed.nix
# ───────
# Zed editor (the GUI code editor). Installed via Home Manager.
# `userSettings` here become ~/.config/zed/settings.json.
#
{ ... }: {
  flake.nixosModules.zed = { ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.zed-editor = {
        enable = true;

        # Editor extensions auto-installed on first launch.
        extensions = [ "html" "git-firefly" "nix" "kdl" ];

        userSettings = {
          # ── UI layout ────────────────────────────────────────────────────
          project_panel.button     = true;
          bottom_dock_layout       = "contained";
          collaboration_panel.dock = "left";
          toolbar.quick_actions    = true;

          # ── Privacy ──────────────────────────────────────────────────────
          # Disable Zed's diagnostic + metrics collection.
          telemetry = {
            diagnostics = false;
            metrics     = false;
          };

          # Skip the "do you trust this folder?" prompt for new worktrees.
          session.trust_all_worktrees = true;

          # ── Look & feel ──────────────────────────────────────────────────
          ui_font_size     = 16;
          buffer_font_size = 15;
          theme            = "Ayu Dark";
        };
      };
    };
  };
}
