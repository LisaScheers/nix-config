{...}: {
  localModules.darwin."homebrew" = {
    inputs,
    localConfig,
    ...
  }: let
    homebrewTaps = {
      "homebrew/core" = inputs.homebrew-core;
      "homebrew/cask" = inputs.homebrew-cask;
    };
  in {
    homebrew = {
      enable = true;
      onActivation.autoUpdate = true;
      onActivation.cleanup = "zap";
      brews = [];
      casks = [];
    };

    nix-homebrew = {
      enable = true;
      user = localConfig.primaryUser;
      taps = homebrewTaps;
      mutableTaps = false;
      enableRosetta = true;
    };
  };
}
