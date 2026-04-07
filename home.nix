{ config, pkgs, lib, inputs, ... }: {

  home.username = "sun";
  home.homeDirectory = "/home/sun";

  home.packages = with pkgs; [
    tree
    ghostty
  ];

  programs.git = {
    enable = true;
    userName = "SunSinD";
    userEmail = "SunpreetSingh22@outlook.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      line_break.disabled = true;
    };
  };

  programs.ghostty.enable = true;

  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
  };

  programs.niri = {
    enable = true;
    settings = {
      layout.gaps = 8;
      binds = {
        "Mod+Return".action.spawn = [ (lib.getExe pkgs.ghostty) ];
        "Mod+Q".action.close-window = [];
        "Mod+Space".action.spawn = [ "dms" "launcher" ];
        "Mod+Left".action.focus-column-left = [];
        "Mod+Right".action.focus-column-right = [];
        "Mod+Up".action.focus-window-up = [];
        "Mod+Down".action.focus-window-down = [];
      };
    };
  };

  home.stateVersion = "25.05";
}
