{ ... }: {
  flake.nixosModules.shell = { ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.starship = {
        enable   = true;
        settings = {
          add_newline         = false;
          aws.disabled        = true;
          gcloud.disabled     = true;
          line_break.disabled = true;
        };
      };

      programs.bash = {
        enable           = true;
        enableCompletion = true;
        shellAliases = {
          rebuild = "sudo nixos-rebuild switch --flake ~/nixconf#$(hostname)";
          update  = "git -C ~/nixconf pull --autostash --rebase && sudo nixos-rebuild switch --flake ~/nixconf#$(hostname)";
        };
      };
    };
  };
}
