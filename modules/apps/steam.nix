{ ... }: {
  flake.nixosModules.steam = { ... }: {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };

    hardware.steam-hardware.enable = true;
  };
}
