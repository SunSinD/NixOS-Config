#
# core.nix
# ────────
# Shared NixOS module that every host (`main-pc`, `vm`, `generic`) imports.
# Anything that should be true *everywhere* lives here: locale, networking,
# the user account, sound, Bluetooth, fonts, the window manager session, etc.
# Host-specific tweaks live in modules/nixos/hosts/<host>/configuration.nix.
#
{ inputs, ... }: {
  flake.nixosModules.core = { config, pkgs, lib, ... }:
  let
    # ── Helper: btrfs swapfile creator ─────────────────────────────────────
    # systemd runs this once on boot to make sure /swapfile exists before
    # the kernel tries to swap on it.
    # Built without Nix '' multiline strings so CRLF / '' rules cannot break systemd's generated wrapper.
    btrfsSwapInit = pkgs.writeShellScript "create-swapfile" (
      lib.concatStringsSep "\n" [
        "set -euo pipefail"
        "if ${pkgs.util-linux}/bin/swapon --show=NAME --noheadings | ${pkgs.gnugrep}/bin/grep -qx /swapfile; then exit 0; fi"
        "rm -f /swapfile"
        "${pkgs.btrfs-progs}/bin/btrfs filesystem mkswapfile --size 8G /swapfile"
      ]
    );

    # ── Helper: niri session launcher ──────────────────────────────────────
    # This is the program greetd starts when you log in. It loads the system
    # environment, sets the right Wayland variables, and then exec's niri.
    sunsdNiriSession = pkgs.writeShellScriptBin "sunsd-niri-session" ''
      set -eu

      log_dir="$HOME/.local/state/niri"
      mkdir -p "$log_dir"
      exec >> "$log_dir/session.log" 2>&1

      # NixOS: environment.variables (e.g. NOCTALIA_SETTINGS_FILE) live here; greetd is not a login shell.
      if [ -r /etc/set-environment ]; then
        set -a
        # shellcheck disable=SC1091
        . /etc/set-environment
        set +a
      fi

      # Must include /run/current-system/sw/bin so niri spawn + sunsd-focus-or-spawn always resolve.
      export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/SunSD/bin''${HOME+:$HOME/.nix-profile/bin}:$PATH"

      export XDG_CURRENT_DESKTOP=niri
      export XDG_SESSION_DESKTOP=niri
      export XDG_SESSION_TYPE=wayland
      export NIXOS_OZONE_WL=1
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      export MOZ_ENABLE_WAYLAND=1

      if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        exec ${pkgs.dbus}/bin/dbus-run-session -- ${lib.getExe config.programs.niri.package}
      fi

      exec ${lib.getExe config.programs.niri.package}
    '';
  in {
    # Pull in the modules from external flakes that we want available system-wide.
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.catppuccin.nixosModules.catppuccin
      inputs.disko.nixosModules.disko
    ];

    # ── Locale & networking ────────────────────────────────────────────────
    # Time zone, the network manager (Wi-Fi / Ethernet), and DNS resolvers.
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
    # Ship binary firmware blobs (Wi-Fi, GPU, etc.) and allow non-free packages.
    hardware.enableRedistributableFirmware = true;
    nixpkgs.config.allowUnfree            = true;

    # ── Swap ───────────────────────────────────────────────────────────────
    # zram = compressed RAM acting as fast swap. The /swapfile on disk is the
    # backing slower swap (created by the systemd unit further down).
    zramSwap = {
      enable    = true;
      algorithm = "zstd";
    };

    swapDevices = [
      { device = "/swapfile"; }
    ];

    # ── Users ──────────────────────────────────────────────────────────────
    # `mutableUsers = false` means users are defined ONLY here in Nix; you
    # can't add/remove them with passwd/useradd. Empty hashedPassword lets
    # you log in without a password (auto-login is configured below).
    users = {
      mutableUsers = false;
      users.SunSD = {
        isNormalUser = true;
        extraGroups  = [ "networkmanager" "wheel" "video" "input" "libvirtd" ];
        hashedPassword = "";
      };
    };

    # ── Security ───────────────────────────────────────────────────────────
    # Passwordless sudo for anyone in the `wheel` group, and PAM allows the
    # empty password set above to actually log in.
    security = {
      sudo.wheelNeedsPassword = false;
      pam.services.login.allowNullPassword = true;
    };

    # ── Bluetooth ──────────────────────────────────────────────────────────
    # Enable the stack at boot and run blueman as the GUI manager.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };

    services.blueman.enable = true;

    # ── Nix daemon settings ────────────────────────────────────────────────
    # `extra-substituters` are extra binary caches; `trusted-public-keys` lets
    # Nix verify their downloads. Trusted-users may use these caches too.
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

    # ── Theme ──────────────────────────────────────────────────────────────
    # Catppuccin theming is currently off; colors come from app-level configs.
    catppuccin = {
      enable = false;
      cursors.enable = false;
    };

    # ── Fonts ──────────────────────────────────────────────────────────────
    # Inter for UI, JetBrains Mono for terminals/editors, Noto for emoji.
    fonts.packages = with pkgs; [
      inter
      jetbrains-mono
      noto-fonts-color-emoji
    ];

    # ── Home Manager ───────────────────────────────────────────────────────
    # Manages user-level dotfiles in the same Nix language. `useGlobalPkgs`
    # makes HM share the system's `pkgs` instead of importing its own.
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
        gtk.gtk4.theme = null;
        xdg.userDirs.setSessionVariables = false;
      };
    };

    # Make .desktop entries from system packages visible to launchers.
    environment.pathsToLink = [ "/share/applications" ];

    # ── XDG portals & default apps ─────────────────────────────────────────
    # Portals are how Wayland apps ask the system for screenshots, file
    # pickers, etc. The MIME table picks the default browser/file manager.
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

    # ── Session environment ────────────────────────────────────────────────
    # Variables exported into every graphical session so apps render natively
    # under Wayland and use a dark GTK theme.
    environment.sessionVariables = {
      NIXOS_OZONE_WL              = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      MOZ_ENABLE_WAYLAND          = "1";
      XDG_CURRENT_DESKTOP         = "niri";
      GTK_THEME                   = "Adwaita:dark";
    };

    # ── Boot loader & kernel quiet flags ───────────────────────────────────
    # Keep multiple generations and show the boot menu briefly so you can
    # choose older configs when needed.
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 3;
    boot.loader.timeout = lib.mkDefault 3;
    # Reduce boot/shutdown noise (and avoids wide "[    OK    ]" status blocks).
    boot.consoleLogLevel = lib.mkDefault 0;
    boot.kernelParams = lib.mkDefault [
      "quiet"
      "loglevel=3"
      "udev.log_level=0"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
    ];

    # ── Graphics ───────────────────────────────────────────────────────────
    # Enable the Mesa stack plus 32-bit libraries so 32-bit apps (Steam, Wine)
    # can use the GPU.
    hardware.graphics = {
      enable      = true;
      enable32Bit = true;
    };

    # ── System services ────────────────────────────────────────────────────
    # Auto-login on tty1, greetd as the display manager (it just runs the
    # niri session script), PipeWire for audio, plus a few utility daemons.
    services = {
      getty.autologinUser = "SunSD";

      greetd = {
        enable = true;
        restart = false;
        settings.default_session = {
          command = lib.getExe sunsdNiriSession;
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
            # overload(meta, f13) breaks Mod+Enter etc. (niri sees F13+key).
          };
        };
      };
    };

    # ── systemd units ──────────────────────────────────────────────────────
    # One-shot unit that runs `btrfsSwapInit` (defined at the top) to create
    # /swapfile right before the kernel mounts it as swap.
    systemd = {
      services = {
        create-swapfile = {
          description = "Create Btrfs swapfile";
          wantedBy = [ "swapfile.swap" ];
          before = [ "swapfile.swap" ];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${btrfsSwapInit}";
          };
        };

        NetworkManager-wait-online.enable = false;
      };

      network.wait-online.enable = false;
    };

    # Unlock the GNOME keyring on login so apps can read stored secrets.
    security.pam.services.greetd.enableGnomeKeyring = true;

    # ── Virtualization (opt-in) ────────────────────────────────────────────
    # libvirt can fail to start on some machines after updates when systemd
    # credentials are TPM-sealed (seen as "TPM key integrity check failed"),
    # which would make `nixos-rebuild switch` fail. Keep it opt-in per-host.
    virtualisation = {
      libvirtd = {
        enable            = lib.mkDefault false;
        qemu.swtpm.enable = lib.mkDefault false;
      };
      spiceUSBRedirection.enable = lib.mkDefault false;
    };

    # ── Misc ───────────────────────────────────────────────────────────────
    # `system.nixos.label` shows the hostname in the systemd-boot menu.
    # `stateVersion` tells NixOS which release semantics to keep stable for
    # this install — DO NOT change it after the system is set up.
    system.nixos.label     = config.networking.hostName;
    security.polkit.enable = true;
    system.stateVersion    = "25.11";
  };
}
