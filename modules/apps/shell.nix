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
          rebuild = "sudo nixos-rebuild switch --option fallback true --option download-attempts 5 --option connect-timeout 20 --flake ~/nixconf#$(hostname) > /tmp/_build.log 2>&1 && echo '  OK: Rebuilt.' || (echo '  ERROR: Rebuild failed.' && grep -i error /tmp/_build.log | head -5)";
          update  = "bash ~/nixconf/scripts/update.sh";
          enable-lanzaboote = "bash ~/nixconf/scripts/enable-lanzaboote.sh";
          finish-install = "bash ~/nixconf/scripts/finish-install.sh";
        };
      };
    };
  };
}
