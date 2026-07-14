{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./_hardware-configuration.nix
    ./disko-config.nix
    ./networking.nix
    ./mailserver.nix
    ./groupware.nix
    ./monitoring.nix
    ./tunnel.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    htop
    mariadb
    rsync
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.domain = "scheers.tech";
  time.timeZone = "Europe/Brussels";

  boot.loader.grub = {
    enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users = {
    root.hashedPassword = "!";
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

  security.acme = {
    acceptTerms = true;
    defaults.email = "lisa@scheers.tech";
  };

  system.stateVersion = "26.05";
}
