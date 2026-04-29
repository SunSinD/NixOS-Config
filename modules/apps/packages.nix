{ inputs, ... }: {
  flake.nixosModules.packages = { pkgs, ... }: {
    home-manager.users.SunSD = { pkgs, ... }: {
      home.packages = with pkgs; [
        # ── CLI tools ──────────────────────────────────────────────────────────
        neovim
        curl
        lstr
        bat
        fastfetch
        btop
        zip
        unzip
        wget

        # ── Theming ────────────────────────────────────────────────────────────
        adwaita-icon-theme
        hicolor-icon-theme
        dconf

        # ── Virtualisation ─────────────────────────────────────────────────────
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        virtio-win
        win-spice

        vivaldi
        gpu-screen-recorder
        obsidian
        mpv
        thunar
        codex
      ];
    };
  };
}
