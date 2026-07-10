{inputs, ...}: let
  homebrewTaps = {
    "homebrew/core" = inputs.homebrew-core;
    "homebrew/cask" = inputs.homebrew-cask;
  };
in {
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.cleanup = "check";
    brews = [];
    casks = [];
  };

  nix-homebrew = {
    enable = true;
    user = "lisa";
    taps = homebrewTaps;
    mutableTaps = false;
    enableRosetta = true;
  };
}
