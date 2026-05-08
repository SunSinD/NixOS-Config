{ inputs, ... }: {
  flake.nixosModules.niri = { pkgs, config, ... }:
  let
    noctaliaDeclarativeSettings = pkgs.writeText "noctalia-settings.json" (builtins.readFile ../noctalia/noctalia.json);
    # Avoid carrying store-path context into generated config strings.
    wallpaperPath = builtins.unsafeDiscardStringContext "${../../../assets/wallpapers/clouds.jpg}";
    wallpaperFile = ../../../assets/wallpapers/clouds.jpg;

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

    niriConfigKdl =
      builtins.replaceStrings
        [ "@@NOCTALIA_SETTINGS_FILE@@" "@@WALLPAPER_PATH@@" ]
        [ "${noctaliaDeclarativeSettings}" wallpaperPath ]
        kdlForHost;
  in {
    imports = [ inputs.niri.nixosModules.niri ];

    programs.niri = {
      enable  = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };

    home-manager.users.SunSD = { ... }: {
      programs.niri.config = niriConfigKdl;

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
