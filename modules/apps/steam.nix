#
# steam.nix
# ─────────
# Steam, plus a small launcher (`steam-niri`) that exports the right Wayland
# variables before exec'ing Steam so it picks the modern Vulkan UI under niri.
# `steam-hardware.enable` adds udev rules for Steam Controllers / VR / etc.
#
{ ... }: {
  flake.nixosModules.steam = { pkgs, ... }: {
    # ── System-wide ───────────────────────────────────────────────────────
    programs.steam = {
      enable = true;
      # Open the firewall ports needed for streaming games to other devices.
      remotePlay.openFirewall = true;
    };

    hardware.steam-hardware.enable = true;

    # ── User-level launcher + .desktop entry ──────────────────────────────
    home-manager.users.SunSD = { ... }: {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "steam-niri";
          runtimeInputs = [ pkgs.steam ];
          text = ''
            export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"
            export XDG_CURRENT_DESKTOP="''${XDG_CURRENT_DESKTOP:-niri}"
            exec steam -vgui "$@"
          '';
        })
      ];

      home.file = {
        ".local/share/applications/steam.desktop".text = ''
          [Desktop Entry]
          Name=Steam
          GenericName=Game Launcher
          Comment=Launch Steam
          Exec=steam-niri %U
          Icon=${pkgs.steam}/share/icons/hicolor/256x256/apps/steam.png
          Terminal=false
          Type=Application
          Categories=Network;FileTransfer;Game;
          MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
        '';
      };
    };
  };
}
