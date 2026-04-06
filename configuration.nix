{ config, pkgs, inputs, ... }: {

  imports = [
    ./disko-config.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.enableRedistributableFirmware = true;

  networking.hostName = "SunSD";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Montreal";
  i18n.defaultLocale = "en_CA.UTF-8";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  users.users.sun = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  programs.niri.enable = true;
  services.displayManager.defaultSession = "niri";

  security.polkit.enable = true;
  security.sudo.enable = true;

  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "65536"; }
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    ghostty
    vivaldi
    discord
  ];

  environment.variables.EDITOR = "vim";

  system.stateVersion = "25.05";
}
