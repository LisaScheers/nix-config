{
  withSystem,
  inputs,
  ...
}: {
  flake.darwinConfigurations."Lisas-private-MacBook-Pro" = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {inherit inputs;};
    modules = [
      inputs.sops-nix.darwinModules.sops
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      ({
        pkgs,
        lib,
        config,
        ...
      }: {
        nixpkgs = {
          pkgs = withSystem config.nixpkgs.hostPlatform.system (
            {pkgs, ...}:
            # perSystem module arguments
              pkgs
          );
        };
        nix.enable = false; # managed by determinate nix installer
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = [
          pkgs.vim
          pkgs.just
          pkgs.sops
          pkgs.age
          pkgs.ssh-to-age
          inputs.alejandra.packages."aarch64-darwin".default
          inputs.nil.packages."aarch64-darwin".nil
          pkgs.jdk21_headless
          pkgs.codex
          pkgs.ripgrep
        ];

        # homebrew packages
        homebrew = {
          enable = true;
          onActivation.autoUpdate = true;
          onActivation.cleanup = "zap";
          brews = [
            #"azure-functions-core-tools@4" # disabled because not used currently
            "graphite"
          ];
          casks = [
            "raycast"
            "alacritty"
            "vlc"
            "codexbar"
          ];
        };

        home-manager = {
          backupFileExtension = ".before-nix-home-manager";
          useGlobalPkgs = true;
          useUserPackages = true;
          users.lisa = {
            imports = [
              inputs.onepassword-shell-plugins.hmModules.default
              ../../../home/lisa/mac-private.nix
            ];
          };
          extraSpecialArgs = {inherit inputs pkgs;};
        };

        nix-homebrew = {
          enable = true;
          user = "lisa";
          taps = {
            "homebrew/homebrew-core" = inputs.homebrew-core;
            "homebrew/homebrew-cask" = inputs.homebrew-cask;
            "azure/homebrew-functions" = inputs.azure-functions;
            "messense/homebrew-macos-cross-toolchains" = inputs.macos-cross-toolchains;
            "surrealdb/homebrew-tap" = inputs.surrealdb-tap;
            "withgraphite/homebrew-tap" = inputs.withgraphite-tap;
            "steipete/homebrew-tap" = inputs.steipete-tap;
          };
          mutableTaps = false;
          enableRosetta = true;
        };

        system.primaryUser = "lisa";
        users.users.lisa.uid = 501;
        # pam touch id
        security.pam.services.sudo_local.touchIdAuth = true;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";
        nix.settings.trusted-users = ["lisa"];
        launchd.daemons.nix-store-gc = {
          serviceConfig = {
            Label = "org.nix-darwin.nix-store-gc";
            ProgramArguments = [
              "/bin/sh"
              "-lc"
              "/run/current-system/sw/bin/nix-collect-garbage --delete-older-than 14d"
            ];
            StartCalendarInterval = [{
              Hour = 5;
              Minute = 0;
              Weekday = 0;
            }];
            StandardOutPath = "/var/log/nix-store-gc.log";
            StandardErrorPath = "/var/log/nix-store-gc.log";
          };
        };

        # Apply updates from the latest flake revision every day.
        launchd.daemons.nix-darwin-auto-upgrade = {
          serviceConfig = {
            Label = "org.nix-darwin.auto-upgrade";
            ProgramArguments = [
              "/bin/sh"
              "-lc"
              "/run/current-system/sw/bin/darwin-rebuild switch --flake /private/etc/nix-darwin#Lisas-private-MacBook-Pro"
            ];
            StartCalendarInterval = [{
              Hour = 4;
              Minute = 0;
            }];
            StandardOutPath = "/var/log/nix-darwin-auto-upgrade.log";
            StandardErrorPath = "/var/log/nix-darwin-auto-upgrade.log";
          };
        };

        # Enable alternative shell support in nix-darwin.

        # Set Git commit hash for darwin-version.
        system.configurationRevision = lib.mkIf (builtins.pathExists /private/etc/nix-darwin/.git) (lib.mkDefault null);

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 6;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        # Sops-nix configuration
        sops = {
          defaultSopsFile = ../../../../secrets/secrets.yaml;
          age.keyFile = "/Users/lisa/.config/sops/age/keys.txt";
          secrets = {};
        };
      })
    ];
  };
}
