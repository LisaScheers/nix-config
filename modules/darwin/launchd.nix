{...}: {
  localModules.darwin."launchd" = {
    lib,
    localConfig,
    ...
  }: {
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
    };
  };
}
