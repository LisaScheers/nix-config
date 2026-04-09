{
  description = "Multi-host Nix configuration for Darwin and NixOS";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    nil = {
      url = "github:oxalica/nil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "https://flakehub.com/f/kamadorueda/alejandra/4.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko = {
    #   url = "https://flakehub.com/f/nix-community/disko/1.*";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.*";
    };
    fh = {
      url = "https://flakehub.com/f/DeterminateSystems/fh/*";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
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

    azure-functions = {
      url = "github:Azure/homebrew-functions";
      flake = false;
    };
    macos-cross-toolchains = {
      url = "github:messense/homebrew-macos-cross-toolchains";
      flake = false;
    };
    surrealdb-tap = {
      url = "github:surrealdb/homebrew-tap";
      flake = false;
    };

    withgraphite-tap = {
      url = "github:withgraphite/homebrew-tap";
      flake = false;
    };

    steipete-tap = {
      url = "github:steipete/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: let
      privateDarwinModule = import ./hosts/darwin/Lisas-private-MacBook-Pro/default.nix;
      workDarwinModule = import ./hosts/darwin/work/default.nix;
    in {
      imports = [
        inputs.devenv.flakeModule
        ./devshell.nix
        ./overlays.nix
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      flake = {
        darwinConfigurations = {
          "Lisas-private-MacBook-Pro" =
            (privateDarwinModule {
              inherit inputs withSystem;
            }).flake.darwinConfigurations."Lisas-private-MacBook-Pro";
          work = (workDarwinModule {inherit inputs;}).flake.darwinConfigurations.work;
        };
        nixosConfigurations.home-server = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inputs = builtins.removeAttrs inputs ["self"];};
          modules = [
            ./hosts/linux/home-server/default.nix
          ];
        };
      };
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };
    });
}
