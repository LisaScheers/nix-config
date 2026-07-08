{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./minecraft.nix
    ./mastodon.nix
    ./monitoring.nix
    ./stock-keeper.nix
    ./shop-empty-track.nix
    ./authentik.nix
    ./bluesky-pds.nix
    ./disko-config.nix
    ./forgejo-runner.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    htop
    tailscale
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.domain = "bylisa.dev";

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
    extraSetFlags = [ "--accept-dns=false" ];
  };

  users.users = {
    root.hashedPassword = "!"; # Disable root login
    lisa = {
      hashedPassword = "!";
      isNormalUser = true;
      description = "Lisa user";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFzIIn0D0sH6Pual0iAlciIDZo6T0qlWWCgRpQhq8U3"
      ];
    };
    matrix-synapse.extraGroups = [ "matrix-secrets" ];
    turnserver.extraGroups = [ "matrix-secrets" ];
  };
  users.groups.matrix-secrets = { };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "lisa@scheers.tech";

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  sops.secrets."auto-sync-update-env" = {
    sopsFile = ../../../secrets/auto-sync-update.env;
    format = "dotenv";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets."matrix-registration-secret" = {
    sopsFile = ../../../secrets/matrix.json;
    format = "json";
    key = "matrix_registration_secret";
    owner = "matrix-synapse";
    group = "matrix-synapse";
    mode = "0400";
    restartUnits = [ "matrix-synapse.service" ];
  };

  sops.secrets."matrix-turn-secret" = {
    sopsFile = ../../../secrets/matrix.json;
    format = "json";
    key = "matrix_turn_secret";
    owner = "root";
    group = "matrix-secrets";
    mode = "0440";
    restartUnits = [
      "coturn.service"
      "matrix-synapse.service"
    ];
  };

  services.autoSyncUpdate = {
    enable = true;
    flakeHost = "atlas";
    environmentFile = config.sops.secrets."auto-sync-update-env".path;
  };

  matrix = {
    enable = true;
    rootDomain = "bylisa.dev";
    subDomain = "matrix";
    turnRealm = "turn.bylisa.dev";
    registrationSecretFile = config.sops.secrets."matrix-registration-secret".path;
    turnSecretFile = config.sops.secrets."matrix-turn-secret".path;
  };

  system.stateVersion = "25.05";
}
