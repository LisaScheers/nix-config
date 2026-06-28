{...}: {
  localModules.nixos."home-server-onepassword-connect" = {config, ...}: let
    credentialsPath = config.sops.secrets."1password-connect-credentials".path;
    dataDir = "/var/lib/onepassword-connect/data";
    credentialsContainerPath = "/home/opuser/.op/1password-credentials.json";
    dataContainerPath = "/home/opuser/.op/data";

    commonContainerConfig = {
      pull = "newer";
      autoStart = true;
      capabilities.NET_BROADCAST = true;
      environment = {
        OP_HTTP_PORT = "8080";
        OP_LOG_LEVEL = "info";
        OP_SESSION = credentialsContainerPath;
      };
      volumes = [
        "${credentialsPath}:${credentialsContainerPath}:ro"
        "${dataDir}:${dataContainerPath}"
      ];
    };
  in {
    sops.secrets."1password-connect-credentials" = {
      key = "data/1password-connect-credentials";
      owner = "root";
      group = "nscd";
      mode = "0440";
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0700 999 999 -"
    ];

    virtualisation = {
      podman.enable = true;
      oci-containers = {
        backend = "podman";
        containers = {
          op-connect-sync =
            commonContainerConfig
            // {
              image = "1password/connect-sync:latest";
            };

          op-connect-api =
            commonContainerConfig
            // {
              image = "1password/connect-api:latest";
              dependsOn = ["op-connect-sync"];
              ports = [
                "127.0.0.1:8080:8080"
              ];
            };
        };
      };
    };

    systemd.services = {
      podman-op-connect-api.unitConfig.RequiresMountsFor = dataDir;
      podman-op-connect-sync.unitConfig.RequiresMountsFor = dataDir;
    };
  };
}
