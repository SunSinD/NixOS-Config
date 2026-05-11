#
# shell.nix
# ─────────
# The interactive shell setup: the Starship prompt + Bash with the project's
# convenience aliases (`rebuild`, `update`, etc.).
#
{ ... }: {
  flake.nixosModules.shell = { ... }: {
    home-manager.users.SunSD = { ... }: {
      # ── Starship prompt ─────────────────────────────────────────────────
      # Compact prompt; expensive cloud modules (aws / gcloud) are disabled
      # so the prompt never stalls in unrelated directories.
      programs.starship = {
        enable   = true;
        settings = {
          add_newline         = false;
          scan_timeout        = 1000;
          command_timeout     = 1000;
          aws.disabled        = true;
          gcloud.disabled     = true;
          line_break.disabled = true;
        };
      };

      # ── Bash ────────────────────────────────────────────────────────────
      # Aliases for everyday system maintenance:
      #   rebuild             — nixos-rebuild switch with retries (logged)
      #   update              — git pull + rebuild
      #   enable-lanzaboote   — turn on Secure Boot (Lanzaboote)
      #   finish-install      — post-install setup wizard
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
