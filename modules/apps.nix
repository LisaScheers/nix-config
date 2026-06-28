{
  inputs,
  localLib,
  ...
}: {
  perSystem = {
    inputs',
    lib,
    pkgs,
    system,
    ...
  }: let
    hostKind = localLib.hostKindForSystem system;
    rebuildRuntimeInputs =
      [pkgs.nix]
      ++ lib.optionals (hostKind == "darwin") [
        inputs'.nix-darwin.packages.darwin-rebuild
      ];
    mkWorkflowApp = name: runtimeInputs:
      localLib.mkWorkflowApp {
        inherit
          hostKind
          lib
          name
          pkgs
          runtimeInputs
          system
          ;
      };
    buildApp = mkWorkflowApp "build" rebuildRuntimeInputs;
    buildSwitchApp = mkWorkflowApp "build-switch" rebuildRuntimeInputs;
    deployHomeServerApp = mkWorkflowApp "deploy-home-server" [
      pkgs.coreutils
      pkgs.gnutar
      pkgs.gzip
      pkgs.openssh
      pkgs.sshpass
    ];
    hostApps = lib.optionalAttrs (localLib.hasHostForSystem system) {
      default = buildApp;
      build = buildApp;
      "build-switch" = buildSwitchApp;
      apply = buildSwitchApp;
    };
  in {
    apps =
      {
        clean = mkWorkflowApp "clean" [pkgs.nix];
        update = mkWorkflowApp "update" [
          pkgs.git
          pkgs.nix
        ];
        deploy-home-server = deployHomeServerApp;
      }
      // hostApps;
  };
}
