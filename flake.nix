{
  description = "Multi-host Nix configuration for Darwin and NixOS";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.*";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-authentik = {
      url = "github:LisaScheers/nixpkgs/5105c5e9cf1a92c4888ede41a2e8deb733282feb";
    };
    stock-keeper = {
      url = "github:LisaScheers/stock-keeper/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shop-empty-track = {
      url = "github:LisaScheers/shop-empty-track/main";
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

  outputs = inputs @ {flake-parts, ...}: let
    localConfig = import ./config.nix;
    localLib = import ./lib {
      inherit localConfig;
      appsDir = ./apps;
      root = ./.;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} ({
      config,
      withSystem,
      ...
    }: {
      _module.args.localConfig = localConfig;

      imports = [
        inputs.home-manager.flakeModules.home-manager
        ./devshell.nix
        ./overlays.nix
        ./hosts/darwin/Lisas-private-MacBook-Pro/default.nix
        ./modules/authentik
        ./modules/forgejo-runner
        ./modules/matrix
        ./hosts/linux/matrix.bylisa.dev
      ];
      systems = localConfig.supportedSystems;
      flake = {
        homeModules.lisa-macos = {
          imports = [
            inputs.onepassword-shell-plugins.hmModules.default
            ./home/lisa/mac-private.nix
          ];
        };

        nixosConfigurations.${localConfig.nixosHost} = inputs.nixpkgs.lib.nixosSystem {
          system = localConfig.nixosSystem;
          specialArgs = {
            inputs = builtins.removeAttrs inputs ["self"];
            flakeRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            inherit localConfig;
          };
          modules = [
            inputs.disko.nixosModules.disko
            inputs.sops-nix.nixosModules.sops
            ./hosts/linux/home-server/default.nix
          ];
        };
      };
      perSystem = {
        inputs',
        lib,
        pkgs,
        system,
        ...
      }: let
        hostKind = localLib.hostKindForSystem system;
        rebuildRuntimeInputs =
          [pkgs.nix]
          ++ lib.optionals (hostKind == "darwin") [
            inputs'.nix-darwin.packages.darwin-rebuild
          ];
        mkWorkflowApp = name: runtimeInputs:
          localLib.mkWorkflowApp {
            inherit
              hostKind
              lib
              name
              pkgs
              runtimeInputs
              system
              ;
          };
        buildApp = mkWorkflowApp "build" rebuildRuntimeInputs;
        buildSwitchApp = mkWorkflowApp "build-switch" rebuildRuntimeInputs;
        deployHomeServerApp = mkWorkflowApp "deploy-home-server" [
          pkgs.coreutils
          pkgs.gnutar
          pkgs.gzip
          pkgs.openssh
          pkgs.sshpass
        ];
        nixSource = localLib.mkNixSource lib;
        formattingCheck = localLib.mkFormattingCheck {
          inherit pkgs;
          src = nixSource;
        };
        hostApps = lib.optionalAttrs (localLib.hasHostForSystem system) {
          default = buildApp;
          build = buildApp;
          "build-switch" = buildSwitchApp;
          apply = buildSwitchApp;
        };
      in {
        apps =
          {
            clean = mkWorkflowApp "clean" [pkgs.nix];
            update = mkWorkflowApp "update" [
              pkgs.git
              pkgs.nix
            ];
            deploy-home-server = deployHomeServerApp;
          }
          // hostApps;

        checks = {
          default = formattingCheck;
          formatting = formattingCheck;
        };

        formatter = localLib.mkFormatter pkgs;
      };
    });
}
