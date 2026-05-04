{ inputs, ... }: {
  flake.nixosModules.core = { config, pkgs, lib, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.catppuccin.nixosModules.catppuccin
      inputs.disko.nixosModules.disko
    ];

    time.timeZone                          = "America/Montreal";
    networking.networkmanager.enable       = true;
    networking.networkmanager.dns          = "systemd-resolved";
    networking.networkmanager.wifi.powersave = false;
    networking.nameservers                = [ "1.1.1.1" "8.8.8.8" "1.0.0.1" "8.8.4.4" ];
    services.resolved = {
      enable   = true;
      settings.Resolve.DNSSEC       = "false";
      settings.Resolve.FallbackDNS  = [ "1.1.1.1" "8.8.8.8" ];
    };
    hardware.enableRedistributableFirmware = true;
    nixpkgs.config.allowUnfree            = true;

    zramSwap = {
      enable    = true;
      algorithm = "zstd";
    };

    users.users.SunSD = {
      isNormalUser    = true;
      extraGroups     = [ "networkmanager" "wheel" "video" "input" "libvirtd" ];
      initialHashedPassword = "";
    };

    security.sudo.wheelNeedsPassword = false;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };

    services.blueman.enable = true;

    nix.settings = {
      trusted-users         = [ "root" "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
      fallback              = true;
      download-attempts     = 5;
      connect-timeout       = 20;

      extra-substituters        = [ "https://niri.cachix.org" "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };

    catppuccin = {
      enable = false;
      cursors.enable = false;
    };

    fonts.packages = with pkgs; [ inter jetbrains-mono noto-fonts-color-emoji ];

    home-manager = {
      useGlobalPkgs   = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      users.SunSD = { ... }: {
        home = {
          username      = "SunSD";
          homeDirectory = "/home/SunSD";
          stateVersion  = "25.11";
        };
      };
    };

    environment.pathsToLink = [ "/share/applications" ];

    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
        config.niri = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        };
      };

      mime.defaultApplications = {
        "x-scheme-handler/http"  = "vivaldi-stable.desktop";
        "x-scheme-handler/https" = "vivaldi-stable.desktop";
        "text/html"              = "vivaldi-stable.desktop";
        "inode/directory"        = "thunar.desktop";
        "x-scheme-handler/file"  = "thunar.desktop";
      };
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL              = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      MOZ_ENABLE_WAYLAND          = "1";
      XDG_CURRENT_DESKTOP         = "niri";
      GTK_THEME                   = "Adwaita:dark";
    };

    boot.loader.systemd-boot.configurationLimit = lib.mkForce 1;
    boot.loader.timeout = lib.mkForce 0;
    boot.consoleLogLevel = 0;
    boot.kernelParams = [ "quiet" "udev.log_level=3" ];

    hardware.graphics = {
      enable      = true;
      enable32Bit = true;
    };

    services = {
      greetd = {
        enable = true;
        restart = false;
        settings.default_session = {
          command = "niri-session";
          user = "SunSD";
        };
      };

      pipewire = {
        enable       = true;
        alsa.enable  = true;
        pulse.enable = true;
      };

      flatpak.enable = true;
      upower.enable = true;
      power-profiles-daemon.enable = true;
      gnome.gnome-keyring.enable = true;
      dbus.enable = true;
      keyd = {
        enable = true;
        keyboards.default = {
          ids = [ "*" ];
          settings.main = {
            leftmeta = "overload(meta, f13)";
            rightmeta = "overload(meta, f13)";
          };
        };
      };
    };

    security.pam.services.greetd.enableGnomeKeyring = true;

    virtualisation = {
      libvirtd = {
        enable           = true;
        qemu.swtpm.enable = true;
      };
      spiceUSBRedirection.enable = true;
    };

    system.nixos.label     = config.networking.hostName;
    security.polkit.enable = true;
    system.stateVersion    = "25.11";
  };
}
