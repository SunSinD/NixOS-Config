{ ... }: {
  flake.nixosModules.equibop = { ... }: {
    home-manager.users.grey = { pkgs, lib, ... }: {

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
