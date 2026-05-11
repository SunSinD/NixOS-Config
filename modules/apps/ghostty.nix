#
# ghostty.nix
# ───────────
# Ghostty terminal (kept as a backup; the default terminal hotkey opens
# `foot` via sunsd-terminal). Bash integration enables Ghostty's shell
# integration features (semantic prompts, etc.).
#
{ ... }: {
  flake.nixosModules.ghostty = { ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.ghostty = {
        enable                = true;
        enableBashIntegration = true;
        settings = {
          background-opacity = "0.92";
          # Don't show the size overlay popup when resizing the window.
          resize-overlay = "never";
        };
      };
    };
  };
}
