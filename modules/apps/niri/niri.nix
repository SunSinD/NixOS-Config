{ inputs, ... }: {
  flake.nixosModules.niri = { pkgs, ... }: {
    imports = [ inputs.niri.nixosModules.niri ];

    programs.niri = {
      enable  = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };

    home-manager.users.SunSD = { ... }: {
      programs.niri.config = builtins.readFile ./config.kdl;
    };
  };
}
