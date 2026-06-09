{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko-config.nix
    ./bluesky-pds.nix
    ./minecraft.nix
    ./stock-keeper.nix
    ./forgejo-runner.nix
    ./authentik.nix
    ./monitoring.nix
  ];

  networking.domain = "bylisa.dev";
  networking.hostName = "matrix";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # system packages
  environment.systemPackages = with pkgs; [
    git
    htop
    tailscale
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.tailscale = {
    enable = true;
    extraSetFlags = ["--accept-dns=false"];
  };

  users.users = {
    root.hashedPassword = "!"; # Disable root login
    lisa = {
      hashedPassword = "!";
      isNormalUser = true;
      description = "Lisa user";
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFzIIn0D0sH6Pual0iAlciIDZo6T0qlWWCgRpQhq8U3"
      ];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "lisa@scheers.tech";

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];

  system.stateVersion = "25.05";
}
