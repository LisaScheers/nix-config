{...}: {
  localModules.nixos."home-server-vaultwarden" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    primaryDomain = "vault.bylisa.dev";
    vaultwardenAddress = "127.0.0.1";
    vaultwardenPort = 8222;
    backupRoot = "/srv/disks/western-digital-hdd/vaultwarden";
    backupDir = "${backupRoot}/backup";
    proxyErrorPage = import ./_nginx-error-page.nix {inherit pkgs;};
  in {
    sops.useSystemdActivation = true;

    sops.secrets = {
      "vaultwarden-env" = {
        sopsFile = ../../../secrets/vaultwarden.env;
        format = "dotenv";
        owner = "vaultwarden";
        group = "vaultwarden";
        mode = "0400";
      };

      "vaultwarden-restic-env" = {
        sopsFile = ../../../secrets/vaultwarden-restic.env;
        format = "dotenv";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      "vaultwarden-restic-ssh-key" = {
        sopsFile = ../../../secrets/vaultwarden-restic-ssh.json;
        format = "json";
        key = "private-key";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    services.cloudflare-dyndns.domains = [primaryDomain];

    services.tailscale.enable = true;

    security.acme.certs.${primaryDomain} = {
      extraLegoFlags = [
        "--dns.propagation-wait"
        "30s"
      ];
      group = "nginx";
      reloadServices = ["nginx.service"];
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      backupDir = backupDir;
      environmentFile = config.sops.secrets."vaultwarden-env".path;
      config = {
        DOMAIN = "https://${primaryDomain}";
        ENABLE_WEBSOCKET = true;
        INVITATIONS_ALLOWED = true;
        ROCKET_ADDRESS = vaultwardenAddress;
        ROCKET_PORT = vaultwardenPort;
        SHOW_PASSWORD_HINT = false;
        SIGNUPS_ALLOWED = false;
      };
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      upstreams.vaultwarden.servers."${vaultwardenAddress}:${toString vaultwardenPort}" = {};
      virtualHosts.${primaryDomain} = lib.mkMerge [
        proxyErrorPage
        {
          forceSSL = true;
          useACMEHost = primaryDomain;
          locations = {
            "/" = {
              proxyPass = "http://vaultwarden";
              proxyWebsockets = true;
            };
            "= /notifications/anonymous-hub" = {
              proxyPass = "http://vaultwarden";
              proxyWebsockets = true;
            };
            "= /notifications/hub" = {
              proxyPass = "http://vaultwarden";
              proxyWebsockets = true;
            };
          };
        }
      ];
    };

    services.restic.backups.vaultwarden = {
      paths = [backupDir];
      environmentFile = config.sops.secrets."vaultwarden-restic-env".path;
      initialize = true;
      backupPrepareCommand = ''
        ${config.systemd.package}/bin/systemctl start backup-vaultwarden.service
      '';
      extraOptions = [
        "sftp.command='ssh vaultwarden-backup@matrix -i ${config.sops.secrets."vaultwarden-restic-ssh-key".path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -s sftp'"
      ];
      extraBackupArgs = [
        "--one-file-system"
        "--tag"
        "vaultwarden"
        "--tag"
        "home-server"
      ];
      pruneOpts = [
        "--keep-daily 14"
        "--keep-weekly 8"
        "--keep-monthly 12"
        "--group-by tags"
      ];
      checkOpts = [
        "--read-data-subset=5%"
      ];
      timerConfig = {
        OnCalendar = "03:15";
        Persistent = true;
        RandomizedDelaySec = "45m";
      };
    };

    systemd.services = {
      backup-vaultwarden.unitConfig.RequiresMountsFor = backupRoot;
      restic-backups-vaultwarden = {
        after = ["sops-install-secrets.service"];
        requires = ["sops-install-secrets.service"];
        unitConfig.RequiresMountsFor = backupRoot;
      };
      vaultwarden = {
        after = ["sops-install-secrets.service"];
        requires = ["sops-install-secrets.service"];
      };
    };
  };
}
