{config, ...}: let
  credentialsPath = config.age.secrets.onepassword-connect-credentials.path;
  dataDir = "/var/lib/onepassword-connect/data";
  credentialsContainerPath = "/home/opuser/.op/1password-credentials.json";
  dataContainerPath = "/home/opuser/.op/data";

  commonContainerConfig = {
    pull = "missing";
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
  age.secrets.onepassword-connect-credentials = {
    file = ../../agenix/secrets/nook/onepassword-connect-credentials.age;
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
            image = "1password/connect-sync@sha256:6297ca6136c0f0fb096bc64c49e1bc8df2aab35282ebff8c7bb60745ef176d0d";
          };

        op-connect-api =
          commonContainerConfig
          // {
            image = "1password/connect-api@sha256:e915c0c843972f02b0e7e2de502bda8bd4a092288b3f1866098a857bd715a281";
            dependsOn = ["op-connect-sync"];
            ports = [
              "127.0.0.1:8080:8080"
            ];
          };
      };
    };
  };

  systemd.services = {
    podman-op-connect-api = {
      unitConfig.RequiresMountsFor = dataDir;
      restartTriggers = [../../agenix/secrets/nook/onepassword-connect-credentials.age];
    };
    podman-op-connect-sync = {
      unitConfig.RequiresMountsFor = dataDir;
      restartTriggers = [../../agenix/secrets/nook/onepassword-connect-credentials.age];
    };
  };
}
