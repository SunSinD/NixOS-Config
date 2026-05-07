{ inputs, ... }: {
  flake.nixosModules.niri = { pkgs, config, ... }:
  let
    noctaliaDeclarativeSettings = pkgs.writeText "noctalia-settings.json" (builtins.readFile ../noctalia/noctalia.json);

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
      in
      if config.networking.hostName == "main-pc" then raw
      else if config.networking.hostName == "vm" then stripVmVirtual (stripAsus raw)
      else stripAsus raw;

    niriConfigKdl = builtins.replaceStrings [ "@@NOCTALIA_SETTINGS_FILE@@" ] [
      "${noctaliaDeclarativeSettings}"
    ] kdlForHost;
  in {
    imports = [ inputs.niri.nixosModules.niri ];

    programs.niri = {
      enable  = true;
      package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
    };

    home-manager.users.SunSD = { ... }: {
      programs.niri.config = niriConfigKdl;
    };
  };
}
