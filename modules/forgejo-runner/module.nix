perSystem: {
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.services.forgejo-runner;
  settingsFormat = pkgs.formats.yaml {};

  inherit
    (lib)
    any
    attrValues
    concatMapStringsSep
    escapeShellArg
    getExe
    hasInfix
    literalExpression
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    nameValuePair
    optional
    optionalAttrs
    types
    ;

  hasDockerLabel = instance: any (label: hasInfix ":docker://" label) instance.labels;
  wantsDocker = any hasDockerLabel (attrValues cfg.instances);

  labelArgs = labels:
    concatMapStringsSep " " (label: "--label ${escapeShellArg label}") labels;
in {
  options.services.forgejo-runner = {
    package = mkPackageOption pkgs "forgejo-runner" {};

    instances = mkOption {
      default = {};
      description = "Forgejo runner instances managed with the forgejo-runner package.";
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          enable = mkEnableOption "Forgejo runner instance";

          name = mkOption {
            type = types.str;
            default = name;
            example = literalExpression "config.networking.fqdn";
            description = "Runner name used in systemd and logs.";
          };

          url = mkOption {
            type = types.str;
            example = "https://codeberg.org/";
            description = "Forgejo instance URL.";
          };

          uuid = mkOption {
            type = types.str;
            description = "UUID of the runner registered in Forgejo.";
          };

          tokenEnvironmentFile = mkOption {
            type = types.either types.str types.path;
            description = "Environment file containing TOKEN with the runner token.";
          };

          labels = mkOption {
            type = types.listOf types.str;
            default = ["docker:docker://node:22-bookworm"];
            example = literalExpression ''
              [
                "docker:docker://node:22-bookworm"
                "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
              ]
            '';
            description = "Labels advertised by this runner.";
          };

          settings = mkOption {
            type = types.submodule {
              freeformType = settingsFormat.type;
            };
            default = {};
            description = "Forgejo runner YAML configuration.";
          };
        };
      }));
    };
  };

  config = mkIf (cfg.instances != {}) {
    assertions = [
      {
        assertion = wantsDocker -> config.virtualisation.docker.enable;
        message = "Forgejo runner labels using docker:// require virtualisation.docker.enable = true.";
      }
    ];

    systemd.services = let
      mkRunnerService = instanceName: instance: let
        escapedName = utils.escapeSystemdPath instanceName;
        runtimeDirectory = "forgejo-runner-${escapedName}";
        configFile = settingsFormat.generate "forgejo-runner-${escapedName}.yaml" instance.settings;
        startCommand = "${getExe cfg.package} daemon --config ${configFile} --url ${escapeShellArg instance.url} --uuid ${escapeShellArg instance.uuid} --token-url file:$RUNTIME_DIRECTORY/token ${labelArgs instance.labels}";
      in
        nameValuePair "forgejo-runner-${escapedName}" {
          inherit (instance) enable;

          description = "Forgejo runner ${instance.name}";
          wants = ["network-online.target"] ++ optional (hasDockerLabel instance) "docker.service";
          after = ["network-online.target"] ++ optional (hasDockerLabel instance) "docker.service";
          wantedBy = ["multi-user.target"];

          path = [pkgs.coreutils];
          environment.HOME = "/var/lib/forgejo-runner/${instanceName}";

          serviceConfig =
            {
              DynamicUser = true;
              User = "forgejo-runner";
              StateDirectory = "forgejo-runner";
              RuntimeDirectory = runtimeDirectory;
              WorkingDirectory = "-/var/lib/forgejo-runner/${instanceName}";
              EnvironmentFile = instance.tokenEnvironmentFile;
              Restart = "on-failure";
              RestartSec = 2;
              ExecStartPre = [
                (pkgs.writeShellScript "forgejo-runner-token-${escapedName}" ''
                  set -eu

                  if [ -z "''${TOKEN:-}" ]; then
                    echo "TOKEN is missing from ${instance.tokenEnvironmentFile}" >&2
                    exit 1
                  fi

                  mkdir -p "$STATE_DIRECTORY"/${escapeShellArg instanceName}
                  printf '%s' "$TOKEN" > "$RUNTIME_DIRECTORY/token"
                  chmod 0400 "$RUNTIME_DIRECTORY/token"
                '')
              ];
              ExecStart = "${pkgs.bash}/bin/bash -c ${escapeShellArg "unset TOKEN; exec ${startCommand}"}";
              NoNewPrivileges = true;
            }
            // optionalAttrs (hasDockerLabel instance) {
              SupplementaryGroups = ["docker"];
            };
        };
    in
      mapAttrs' mkRunnerService cfg.instances;
  };
}
