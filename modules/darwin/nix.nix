{localConfig, ...}: {
  nix.enable = false;

  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [localConfig.primaryUser];
  };
}
