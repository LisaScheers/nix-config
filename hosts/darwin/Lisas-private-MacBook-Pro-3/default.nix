{
  config,
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
  ];

  # pam touch id
  security.pam.services.sudo_local.touchIdAuth = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = lib.mkIf (builtins.pathExists /etc/nixos/.git) (lib.mkDefault null);

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
}
