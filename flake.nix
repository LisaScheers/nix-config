{
  description = "Multi-host Nix configuration for Darwin and NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    alejandra = {
      url = "github:kamadorueda/alejandra/4.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    sops-nix,
    nix-homebrew,
    nil,
    homebrew-core,
    homebrew-cask,
    alejandra,
    ...
  }: let
    # Helper function to get system-specific pkgs
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    # Darwin configurations
    darwinConfigurations."Lisas-private-MacBook-Pro-3" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {inherit inputs;};
      modules = [
        {
          environment.systemPackages = [
            alejandra.packages."aarch64-darwin".default
            nil.packages."aarch64-darwin".nil
          ];
        }
        ./hosts/darwin/Lisas-private-MacBook-Pro-3/default.nix
        sops-nix.darwinModules.sops
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            backupFileExtension = ".before-nix-home-manager";
            useGlobalPkgs = true;
            useUserPackages = true;
            users.lisa = {
              imports = [./home/lisa/home.nix];
            };
            extraSpecialArgs = {inherit inputs;};
          };
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = "lisa";
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            mutableTaps = false;
            enableRosetta = true;
          };
        }
      ];
    };
    # Development shell
    devShells."aarch64-darwin".default = let
      pkgs = pkgsFor "aarch64-darwin";
      nilPkgs = nil.packages."aarch64-darwin";
      nix-darwin-pkgs = nix-darwin.packages."aarch64-darwin";
    in
      pkgs.mkShell {
        buildInputs = with pkgs; [
          just
          sops
          age
          ssh-to-age
          nilPkgs.nil
          nix-darwin-pkgs.darwin-rebuild
          inputs.home-manager.packages."aarch64-darwin".home-manager
        ];
        shellHook = ''
          echo "Nix Config Development Shell"
          echo "Available commands:"
          echo "  just fmt          - Format all Nix files"
          echo "  just darwin       - Rebuild Darwin configuration"
          echo "  just nixos        - Rebuild NixOS configuration"
          echo "  just sops         - Edit secrets"
          echo "  just check        - Check flake"
        '';
      };

    devShells."x86_64-linux".default = let
      pkgs = pkgsFor "x86_64-linux";
      nilPkgs = nil.packages."x86_64-linux";
    in
      pkgs.mkShell {
        buildInputs = with pkgs; [
          just
          nilPkgs.nil
          sops
          age
          ssh-to-age
          inputs.home-manager.packages."x86_64-linux".home-manager
        ];
        shellHook = ''
          echo "Nix Config Development Shell"
          echo "Available commands:"
          echo "  just fmt          - Format all Nix files"
          echo "  just darwin       - Rebuild Darwin configuration"
          echo "  just nixos        - Rebuild NixOS configuration"
          echo "  just sops         - Edit secrets"
          echo "  just check        - Check flake"
        '';
      };
  };
}
