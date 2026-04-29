{ ... }: {
  flake.nixosModules.git = { pkgs, ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.git = {
        enable = true;

        settings.user = {
          name  = "SunSinD";
          email = "SunpreetSingh22@outlook.com";
        };

        settings = {
          credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
          credential.credentialStore = "secretservice";
          init.defaultBranch    = "main";
          help.autocorrect      = 1;
          column.ui             = "auto";
          pull.rebase           = true;
          branch.autosetuprebase = "always";
          push.autoSetupRemote  = true;
          core.editor           = "nvim";
          diff.algorithm        = "histogram";
          merge.conflictstyle   = "zdiff3";
          fetch.prune           = true;
          fetch.all             = true;

          alias = {
            lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            st = "status";
            co = "checkout";
            br = "branch";
          };
        };
      };
    };
  };
}
