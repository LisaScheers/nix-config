{localConfig, ...}: let
  bootstrapPasswordHash = "$6$Mt1/YBbvqiiqdVqb$5UzppHKCHHRlKk/joJIUop3dANyQv3S0hsdwJHWDrITgLdGrVh05CMIvWfzTtMPz4402p3r.HTLh.pQNLE3fm0";
in {
  users.users.root.hashedPassword = bootstrapPasswordHash;

  users.users.${localConfig.primaryUser} = {
    isNormalUser = true;
    description = "Lisa Scheers";
    hashedPassword = bootstrapPasswordHash;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ25EnARSLbWqw6UhR/6GyO2MsxMqE23W9VM495A2xQu"];
  };
}
