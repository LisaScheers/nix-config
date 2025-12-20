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
        ...
      }: {
        nix.enable = false;
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
        ];

        nixpkgs.config.allowUnfree = true;
        # homebrew packages
        homebrew = {
          enable = true;
          onActivation.autoUpdate = true;
          onActivation.cleanup = "zap";
          brews = [
            #"azure-functions-core-tools@4" # disabled because not used currently
          ];
          casks = [
            "raycast"
            "alacritty"
            "vlc"
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
          extraSpecialArgs = {inherit inputs;};
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
        # Enable alternative shell support in nix-darwin.
        # programs.fish.enable = true;

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
