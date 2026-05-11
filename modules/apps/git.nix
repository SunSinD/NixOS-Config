#
# git.nix
# ───────
# Git identity + global config, written to ~/.config/git/config by HM.
# Credentials are stored in the GNOME keyring via git-credential-manager.
#
{ ... }: {
  flake.nixosModules.git = { pkgs, ... }: {
    home-manager.users.SunSD = { ... }: {
      programs.git = {
        enable = true;

        # ── Identity (used as commit author) ─────────────────────────────
        settings.user = {
          name  = "SunSinD";
          email = "SunpreetSingh22@outlook.com";
        };

        settings = {
          # ── Credentials stored in the GNOME keyring ────────────────────
          credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
          credential.credentialStore = "secretservice";

          # ── Sensible defaults ──────────────────────────────────────────
          init.defaultBranch    = "main";          # New repos use `main`
          help.autocorrect      = 1;               # `git stauts` -> `git status`
          column.ui             = "auto";          # Multi-column listings
          pull.rebase           = true;            # `git pull` rebases instead of merging
          branch.autosetuprebase = "always";
          push.autoSetupRemote  = true;            # `git push` creates upstream automatically
          core.editor           = "nvim";
          diff.algorithm        = "histogram";     # Better diffs for moved code
          merge.conflictstyle   = "zdiff3";        # Show common ancestor in conflicts
          fetch.prune           = true;            # Remove deleted remote branches on fetch
          fetch.all             = true;

          # ── Convenience aliases ────────────────────────────────────────
          # `git lg`, `git st`, `git co`, `git br`
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
