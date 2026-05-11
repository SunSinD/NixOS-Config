#
# equibop.nix
# ───────────
# Equibop (a Discord client based on Vesktop). Two pieces:
#
#   1. Wrap the upstream package to force the discrete GPU and enable
#      hardware video decoding via VAAPI (so screen-sharing isn't laggy).
#
#   2. On every Home Manager switch, copy the JSON/CSS configs from this
#      folder into ~/.config/equibop so the app picks them up next launch.
#
{ ... }: {
  flake.nixosModules.equibop = { ... }: {
    home-manager.users.SunSD = { pkgs, lib, ... }: {

      # ── Patched Equibop binary ────────────────────────────────────────────
      home.packages = [
        (pkgs.equibop.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
          postFixup = (old.postFixup or "") + ''
            wrapProgram $out/bin/equibop \
              --add-flags "--force_high_performance_gpu" \
              --add-flags "--enable-features=VaapiVideoDecodeLinuxGL"
          '';
        }))
      ];

      # ── Settings sync ────────────────────────────────────────────────────
      # Copy the local JSON/CSS into the live config dir after HM finishes.
      home.activation.equibopSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        EQUIBOP_DIR="$HOME/.config/equibop"
        mkdir -p "$EQUIBOP_DIR"/settings
        cp ${./quickCss.css} "$EQUIBOP_DIR/settings/quickCss.css"
        cp ${./plugins.json} "$EQUIBOP_DIR/settings/settings.json"
        cp ${./state.json} "$EQUIBOP_DIR/state.json"
        cp ${./settings.json} "$EQUIBOP_DIR/settings.json"
        chmod 644 "$EQUIBOP_DIR/settings/quickCss.css"
        chmod 644 "$EQUIBOP_DIR/settings/settings.json"
        chmod 644 "$EQUIBOP_DIR/state.json"
        chmod 644 "$EQUIBOP_DIR/settings.json"
      '';
    };
  };
}
