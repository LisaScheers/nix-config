{
  lib,
  localConfig,
  ...
}: let
  darwinFlakeRef = "${localConfig.darwinFlakePath}#${localConfig.darwinHost}";
in {
  launchd.daemons = {
    nix-store-gc.serviceConfig = {
      Label = "org.nix-darwin.nix-store-gc";
      ProgramArguments = [
        "/bin/sh"
        "-lc"
        "/run/current-system/sw/bin/nix-collect-garbage --delete-older-than ${lib.escapeShellArg localConfig.garbageCollectionAge}"
      ];
      StartCalendarInterval = [
        {
          Hour = 5;
          Minute = 0;
          Weekday = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-store-gc.log";
      StandardErrorPath = "/var/log/nix-store-gc.log";
    };

    nix-darwin-auto-upgrade.serviceConfig = {
      Label = "org.nix-darwin.auto-upgrade";
      ProgramArguments = [
        "/bin/sh"
        "-lc"
        "echo ${lib.escapeShellArg "Switching Darwin host ${localConfig.darwinHost}"} >&2; exec /run/current-system/sw/bin/darwin-rebuild switch --flake ${lib.escapeShellArg darwinFlakeRef}"
      ];
      StartCalendarInterval = [
        {
          Hour = 4;
          Minute = 0;
        }
      ];
      StandardOutPath = "/var/log/nix-darwin-auto-upgrade.log";
      StandardErrorPath = "/var/log/nix-darwin-auto-upgrade.log";
    };
  };
}
