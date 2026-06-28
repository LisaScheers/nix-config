{config, ...}: let
  flakeConfig = config;
in {
  localModules.nixos."matrix-host" = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      flakeConfig.localModules.nixos."auto-sync-update"
      flakeConfig.localModules.nixos."matrix-host-hardware"
      flakeConfig.localModules.nixos."matrix-host-disko-config"
      flakeConfig.localModules.nixos."matrix-host-bluesky-pds"
      flakeConfig.localModules.nixos."matrix-host-minecraft"
      # flakeConfig.localModules.nixos."matrix-host-stock-keeper"
      flakeConfig.localModules.nixos."matrix-host-forgejo-runner"
      flakeConfig.localModules.nixos."matrix-host-authentik"
      flakeConfig.localModules.nixos."matrix-host-monitoring"
      flakeConfig.localModules.nixos."matrix-host-vaultwarden-backup"
    ];

    networking.domain = "bylisa.dev";
    networking.hostName = "matrix";

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

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

    services.autoSyncUpdate = {
      enable = true;
      flakeHost = "matrix.bylisa.dev";
      environmentFile = config.sops.secrets."auto-sync-update-env".path;
    };

    sops.secrets."auto-sync-update-env" = {
      sopsFile = ../../../secrets/auto-sync-update.env;
      format = "dotenv";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    system.stateVersion = "25.05";
  };
}
