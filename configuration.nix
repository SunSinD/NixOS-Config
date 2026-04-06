{ config, pkgs, inputs, ... }: {

  # Hardware config is generated on each machine locally,
  # so we don't include it in the repo — it gets pulled separately
  imports = [];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Allows proprietary firmware (graphics drivers etc.)
  hardware.enableRedistributableFirmware = true;

  networking.hostName = "SunSD";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Montreal";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable Flakes and the modern nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow closed-source apps like Vivaldi and Discord
  nixpkgs.config.allowUnfree = true;

  # Your user account
  users.users.sunny = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  # Enable niri as the Wayland compositor
  programs.niri.enable = true;

  # Set niri as the default session
  services.displayManager.defaultSession = "niri";

  # Polkit — handles permission popups (required for Wayland)
  security.polkit.enable = true;
  security.sudo.enable = true;

  # XDG portals — how Wayland apps open file pickers, share screens, etc.
  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # Audio via PipeWire (modern replacement for PulseAudio)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Increase open file limits (prevents build failures)
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "65536"; }
  ];

  # System-wide packages (tools everyone on the system can use)
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    # Browsers & apps
    vivaldi
    discord
  ];

  environment.variables.EDITOR = "vim";

  system.stateVersion = "25.05";
}