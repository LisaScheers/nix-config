{
  description = "Lisa's nix configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      home-manager,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          users.users.lisa = {
            name = "lisa";
            home = "/Users/lisa";
          };

          nixpkgs.overlays = [
            (self: super: {
              pnpm = super.pnpm.override {
                nodejs = pkgs.nodejs_20;
              };
            })
          ];

          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.vim
            pkgs.nil
            pkgs.nixfmt-rfc-style
            pkgs.wget
            pkgs.pam-reattach
            pkgs.jetbrains.rider
            pkgs.alacritty
            pkgs.discord
            #pkgs._1password-gui # broken due to needed to be in /Applications
            pkgs._1password
            #pkgs.spotify # uses slow internet archive 
            #pkgs.teams # old version
            pkgs.slack
            pkgs.gh
            pkgs.nodejs_20
            pkgs.pnpm
            pkgs.uutils-coreutils-noprefix
            #pkgs.dotnetCorePackages.dotnet_9.sdk # warning no build cache, building from source, takes a loooooong time
            #pkgs.dotnetCorePackages.dotnet_8.sdk # warning no build cache, building from source, takes a loooooong time
            #pkgs.dotnet-sdk_8
            pkgs.just
          ];

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell on catalina
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          environment.etc."pam.d/sudo_local" = {
            text = ''
              auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
              auth       sufficient     pam_tid.so
            '';
          };

          system.defaults = {
            dock = {
              autohide = true;
            };
          };

          homebrew = {
            enable = true;
            casks = [
              "orbstack"
              "raycast"
              "cursor"
              "spotify"
              "1password"
              "arc"
              "grammarly-desktop"
              "microsoft-office-businesspro"
              "dbngin"
              #"dotnet-sdk@preview" # manual install for now
            ];
            brews = [
              "mas"
            ];
            onActivation = {
              cleanup = "zap";
              autoUpdate = true;
              upgrade = true;
            };
            masApps = {
              "Hass" = 1099568401;
              "WhatsApp Messenger" = 310633997;
              "The Unarchiver" = 425424353;

            };
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.lisa = import ./users/lisa/default.nix;

          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "lisa";

          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lisas-MacBook-Pro-2
      darwinConfigurations."Lisas-MacBook-Pro-2" = nix-darwin.lib.darwinSystem {
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager

          configuration
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Lisas-MacBook-Pro-2".pkgs;
    };
}
