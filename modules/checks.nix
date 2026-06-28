{localLib, ...}: {
  perSystem = {pkgs, ...}: let
    nixSource = localLib.mkNixSource pkgs.lib;
    formattingCheck = localLib.mkFormattingCheck {
      inherit pkgs;
      src = nixSource;
    };
  in {
    checks = {
      default = formattingCheck;
      formatting = formattingCheck;
    };

    formatter = localLib.mkFormatter pkgs;
  };
}
