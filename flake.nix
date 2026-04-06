{
  description = "SunSD NixOS configuration";

  inputs = {
    # nixos-unstable for latest packages (required for DMS)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager — manages user-level config declaratively
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # niri compositor flake — better than the nixpkgs version
    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs";

    # DankMaterialShell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, niri, dms, ... }@inputs: {
    nixosConfigurations.SunSD = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # Pass inputs down so configuration.nix and home.nix can use them
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        # Hook Home Manager into NixOS so it rebuilds with the system
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          # Point to your user and their home.nix file
          home-manager.users.sunny = {
            imports = [
              ./home.nix
              inputs.niri.homeModules.niri
              inputs.dms.homeModules.dank-material-shell
            ];
          };
        }
      ];
    };
  };
}