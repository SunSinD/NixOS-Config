#
# niri.nix
# ────────
# The Niri (scrollable-tiling Wayland compositor) module.
#
# What this file does:
#   1. Reads ./config.kdl (the niri configuration in KDL format).
#   2. Strips per-host blocks (e.g. the ASUS monitor block on the VM host)
#      so unused outputs don't leave niri with a blank screen.
#   3. Substitutes @@WALLPAPER_PATH@@ and @@NOCTALIA_SETTINGS_FILE@@
#      placeholders with paths from the Nix store.
#   4. Hands the final config to programs.niri.
#   5. Defines two user systemd units that keep the wallpaper (swaybg) and
#      the Noctalia shell alive across config reloads / updates.
#
{ inputs, ... }: {
  flake.nixosModules.niri = { pkgs, config, ... }:
  let
    # The full Noctalia settings JSON, materialised in the Nix store so we
    # can inject its path into the niri environment block.
    noctaliaDeclarativeSettings = pkgs.writeText "noctalia-settings.json" (builtins.readFile ../noctalia/noctalia.json);
    # Avoid carrying store-path context into generated config strings.
    wallpaperPath = builtins.unsafeDiscardStringContext "${../../../assets/wallpapers/clouds.jpg}";
    wallpaperFile = ../../../assets/wallpapers/clouds.jpg;

    # ── Per-host KDL transforms ───────────────────────────────────────────
    # Outputs that do not exist (ASUS on a VM, or wrong Virtual-* name) can leave niri with a blank screen.
    kdlForHost =
      let
        raw = builtins.readFile ./config.kdl;
        stripAsus = s: builtins.replaceStrings [
          ''
// MARK_ASUS_OUTPUT_BEGIN
output "ASUS VG279QM" {
    mode "1920x1080@280.000"
}
// MARK_ASUS_OUTPUT_END

''
        ] [ "" ] s;
        stripVmVirtual = s: builtins.replaceStrings [
          ''
// MARK_VM_VIRTUAL_OUTPUT_BEGIN
output "Virtual-1" {
    scale 1.0
}
// MARK_VM_VIRTUAL_OUTPUT_END

''
        ] [ "" ] s;

        stripAllOutputs = s: stripVmVirtual (stripAsus s);
      in
      if config.networking.hostName == "main-pc" then stripVmVirtual raw
      else if config.networking.hostName == "vm" then stripAllOutputs raw
      else stripAllOutputs raw;

    # Final KDL: placeholders replaced with concrete Nix-store paths.
    niriConfigKdl =
      builtins.replaceStrings
        [ "@@NOCTALIA_SETTINGS_FILE@@" "@@WALLPAPER_PATH@@" ]
        [ "${noctaliaDeclarativeSettings}" wallpaperPath ]
        kdlForHost;
  in {
    imports = [ inputs.niri.nixosModules.niri ];

    # Use the latest unstable build of niri from the niri-flake input.
    programs.niri = {
      enable  = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };

    home-manager.users.SunSD = { ... }: {
      programs.niri.config = niriConfigKdl;

      # ── Wallpaper service ───────────────────────────────────────────────
      # Keep wallpaper + shell alive across config reloads/updates (no reboot).
      systemd.user.services.sunsd-swaybg = {
        Unit = {
          Description = "Wallpaper (swaybg)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${wallpaperFile}";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      # ── Noctalia shell service ──────────────────────────────────────────
      # Auto-restart the shell if it crashes. Noctalia reads its settings
      # from the env var NOCTALIA_SETTINGS_FILE (path injected here).
      systemd.user.services.sunsd-noctalia = {
        Unit = {
          Description = "Noctalia shell";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" "dbus.service" ];
        };
        Service = {
          Environment = [ "NOCTALIA_SETTINGS_FILE=${noctaliaDeclarativeSettings}" ];
          ExecStart = "${pkgs.bash}/bin/bash -lc 'exec noctalia-shell >>/tmp/noctalia-shell.log 2>&1'";
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
