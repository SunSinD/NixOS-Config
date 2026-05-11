#
# flake.nix
# ─────────
# This file is the entry point for the whole NixOS configuration.
# A "flake" is just a self-contained Nix project that pins every external
# dependency (`inputs`) to an exact version via `flake.lock`, so builds are
# reproducible across machines and time.
#
{
  description = "NixOS Configuration";

  # ── Inputs ────────────────────────────────────────────────────────────────
  # External flakes this config depends on. Each one is a separate repo that
  # provides packages, NixOS modules, or a kernel.
  #
  # `inputs.nixpkgs.follows = "nixpkgs"` makes a sub-flake reuse OUR nixpkgs
  # instead of pulling its own copy, which keeps builds smaller and consistent.
  inputs = {
    # The main package collection (every package, every NixOS option).
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Performance-oriented Linux kernel (used by the desktop host).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Lets us split the flake into smaller modules under ./modules.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Auto-imports every .nix file under a directory (used for ./modules).
    import-tree.url = "github:vic/import-tree";

    # Manages per-user dotfiles/programs in the same Nix language.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The Noctalia desktop shell (status bar / launcher / widgets).
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure Boot stack for NixOS (signed boot + sbctl helper).
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The Niri scrollable-tiling Wayland compositor.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin color theme module (currently disabled in core.nix).
    catppuccin.url = "github:catppuccin/nix";

    # Declarative disk partitioning (used by the install script).
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Extra niri tooling/modules.
    nirimod = {
      url = "github:srinivasr/nirimod";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Discord (Vencord) configuration.
    nixcord.url = "github:FlameFlag/nixcord";
  };

  # ── Outputs ───────────────────────────────────────────────────────────────
  # What this flake exposes to the outside world: NixOS systems, packages, etc.
  # Most of the actual configuration lives under ./modules and is glued in by
  # `import-tree` below, which auto-imports every .nix file in that folder.
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ (inputs.import-tree ./modules) ];

    # We only build for 64-bit Linux. Add more here for other architectures.
    systems = [ "x86_64-linux" ];

    # Per-system settings. `allowUnfree = true` lets us install proprietary
    # packages (Nvidia drivers, Steam, Vivaldi, etc.).
    perSystem = { system, ... }: {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    };
  };
}
