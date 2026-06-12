{localConfig, ...}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    trusted-users = ["root" localConfig.primaryUser "nix-remote-builder"];
  };
}
