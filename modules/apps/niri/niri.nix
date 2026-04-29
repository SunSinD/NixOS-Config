{ inputs, ... }: {
  flake.nixosModules.niri = { pkgs, lib, ... }: {
    imports = [ inputs.niri.nixosModules.niri ];

    programs.niri = {
      enable  = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };

    home-manager.users.grey = { ... }: {
      programs.niri.config = builtins.readFile ./config.kdl;

      home.packages = [
        (pkgs.symlinkJoin {
          name  = "nirimod";
          paths = [ inputs.nirimod.packages.${pkgs.stdenv.hostPlatform.system}.default ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/nirimod \
              --run 'export NIRIMOD_CONFIG_DIR="$HOME/nixconf/modules/apps/niri"'
          '';
        })
      ];
    };
  };
}
