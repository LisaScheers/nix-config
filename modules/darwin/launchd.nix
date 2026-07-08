{...}: {
  localModules.darwin."launchd" = {
    lib,
    localConfig,
    ...
  }: let
    userHome = localConfig.darwinHomeDirectory;
  in {
    launchd.user.envVariables = {
      PATH = "${userHome}/.local/bin:/etc/profiles/per-user/${localConfig.primaryUser}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      SSH_AUTH_SOCK = "${userHome}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

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
