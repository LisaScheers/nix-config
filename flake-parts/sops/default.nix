{
  inputs,
  lib,
  ...
}: {
  options.flake.darwinModules = lib.mkOption {
    type = with lib.types; lazyAttrsOf unspecified;
    default = {};
  };

  config.flake.nixosModules.security_sops = {
    config,
    lib,
    ...
  }: let
    cfg = config.forge.security.sops;
  in {
    imports = [inputs.sops-nix.nixosModules.sops];

    options.forge.security.sops = {
      enable = lib.mkEnableOption "sops-nix secret management";

      ageSshKeyPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["/etc/ssh/ssh_host_ed25519_key"];
        description = "SSH private-key paths used as age identities at activation time.";
      };
    };

    config = lib.mkIf cfg.enable {
      sops.age.sshKeyPaths = lib.mkDefault cfg.ageSshKeyPaths;
    };
  };

  config.flake.darwinModules.security_sops = {
    config,
    lib,
    ...
  }: let
    cfg = config.forge.security.sops;
  in {
    imports = [inputs.sops-nix.darwinModules.sops];

    options.forge.security.sops = {
      enable = lib.mkEnableOption "sops-nix secret management";

      ageSshKeyPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["/etc/ssh/ssh_host_ed25519_key"];
        description = "SSH private-key paths used as age identities at activation time.";
      };
    };

    config = lib.mkIf cfg.enable {
      sops.age.sshKeyPaths = lib.mkDefault cfg.ageSshKeyPaths;
    };
  };
}
