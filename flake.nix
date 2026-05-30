{
  description = "Multi-host Nix configuration for Darwin and NixOS";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      config,
      withSystem,
      ...
    }: {
      imports = [
        inputs.devenv.flakeModule
        inputs.home-manager.flakeModules.home-manager
        ./devshell.nix
        ./overlays.nix
        ./hosts/darwin/Lisas-private-MacBook-Pro/default.nix
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      flake = {
        homeModules.lisa-macos = {
          imports = [
            inputs.onepassword-shell-plugins.hmModules.default
            ./home/lisa/mac-private.nix
          ];
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
