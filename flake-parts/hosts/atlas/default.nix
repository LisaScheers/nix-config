{
  config,
  pkgs,
  lib,
  ...
}:
let
  autoSyncSecrets = ../../secrets/atlas/auto-sync-update.sops.yaml;
  matrixSecrets = ../../secrets/atlas/matrix.sops.yaml;
in {
  imports = [
    ./_hardware-configuration.nix
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

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "lisa@scheers.tech";

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  sops.secrets = {
    "auto-sync/repository-url" = {
      sopsFile = autoSyncSecrets;
      key = "git/repository_url";
    };
    "auto-sync/git-username" = {
      sopsFile = autoSyncSecrets;
      key = "git/username";
    };
    "auto-sync/git-token" = {
      sopsFile = autoSyncSecrets;
      key = "git/token";
    };
    "auto-sync/smtp-url" = {
      sopsFile = autoSyncSecrets;
      key = "smtp/url";
    };
    "auto-sync/smtp-username" = {
      sopsFile = autoSyncSecrets;
      key = "smtp/username";
    };
    "auto-sync/smtp-password" = {
      sopsFile = autoSyncSecrets;
      key = "smtp/password";
    };
    "auto-sync/smtp-from" = {
      sopsFile = autoSyncSecrets;
      key = "smtp/from";
    };
    "matrix-registration-secret" = {
      sopsFile = matrixSecrets;
      key = "registration_secret";
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0400";
      restartUnits = [ "matrix-synapse.service" ];
    };
    "matrix-turn-secret" = {
      sopsFile = matrixSecrets;
      key = "turn_secret";
      owner = "root";
      group = "matrix-secrets";
      mode = "0440";
      restartUnits = [
        "coturn.service"
        "matrix-synapse.service"
      ];
    };
  };

  sops.templates."auto-sync-update.env" = {
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      AUTO_SYNC_GIT_REPOSITORY_URL=${config.sops.placeholder."auto-sync/repository-url"}
      AUTO_SYNC_GIT_USERNAME=${config.sops.placeholder."auto-sync/git-username"}
      AUTO_SYNC_GIT_TOKEN=${config.sops.placeholder."auto-sync/git-token"}
      AUTO_SYNC_SMTP_URL=${config.sops.placeholder."auto-sync/smtp-url"}
      AUTO_SYNC_SMTP_USERNAME=${config.sops.placeholder."auto-sync/smtp-username"}
      AUTO_SYNC_SMTP_PASSWORD=${config.sops.placeholder."auto-sync/smtp-password"}
      AUTO_SYNC_SMTP_FROM=${config.sops.placeholder."auto-sync/smtp-from"}
    '';
    restartUnits = [ "nix-auto-sync-update.service" ];
  };

  services.autoSyncUpdate = {
    enable = true;
    flakeHost = "atlas";
    environmentFile = config.sops.templates."auto-sync-update.env".path;
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
