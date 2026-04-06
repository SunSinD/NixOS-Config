{ config, pkgs, lib, inputs, ... }: {

  # Who this home config belongs to
  home.username = "sunny";
  home.homeDirectory = "/home/sunny";

  # User-level packages (only available to you, not system-wide)
  home.packages = with pkgs; [
    tree    # Shows folder structure as a tree in terminal
    ghostty # Your terminal
  ];

  # Git configuration — replace with your own name/email
  programs.git = {
    enable = true;
    userName = "SunSD";
    userEmail = "youremail@example.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Starship — a fancy terminal prompt (shows git branch, directory, etc.)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
    };
  };

  # Ghostty terminal config
  programs.ghostty.enable = true;

  # DankMaterialShell — enable and auto-start
  programs.dms-shell = {
    enable = true;
    systemd.enable = true;
  };

  # niri compositor config — keybinds, gaps, layout
  programs.niri = {
    enable = true;
    settings = {
      layout.gaps = 8;
      binds = {
        # Super + Enter opens Ghostty
        "Mod+Return".action.spawn = [ (lib.getExe pkgs.ghostty) ];
        # Super + Q closes the focused window
        "Mod+Q".action.close-window = [];
        # Super + Space opens DMS launcher
        "Mod+Space".action.spawn = [ "dms" "launcher" ];
        # Arrow keys to move focus between windows
        "Mod+Left".action.focus-column-left = [];
        "Mod+Right".action.focus-column-right = [];
        "Mod+Up".action.focus-window-up = [];
        "Mod+Down".action.focus-window-down = [];
      };
    };
  };

  home.stateVersion = "25.05";
}