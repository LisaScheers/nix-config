perSystem: {
  lib,
  config,
  ...
}: let
  cfg = config.matrix;
in {
  imports = [
    ./synapse.nix
    ./coturn.nix
    ./livekit.nix
  ];
  # configuration options for this module
  options.matrix = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable this module";
    };

    rootDomain = mkOption {
      type = types.str;
      default = null;
      description = "The root domain for the matrix server";
    };

    subDomain = mkOption {
      type = types.str;
      default = "matrix";
      description = "The subdomain for the matrix server";
    };

    turnRealm = mkOption {
      type = types.str;
      default = null;
      description = "The realm for the turn server";
    };

    signupSecret = mkOption {
      type = types.str;
      default = null;
      description = "The secret for the matrix server";
    };
    turnSecret = mkOption {
      type = types.str;
      default = null;
      description = "The secret for the turn server";
    };
  };
}
