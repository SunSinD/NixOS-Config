{ ... }: {
  flake.nixosModules.ghostty = { ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.ghostty = {
        enable                = true;
        enableBashIntegration = true;
        settings = {
          background-opacity = "0.92";
          resize-overlay = "never";
        };
      };
    };
  };
}
