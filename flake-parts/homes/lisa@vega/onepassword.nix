{pkgs, ...}: let
  ghRuntimePath = pkgs.lib.makeBinPath [
    pkgs.gh
    pkgs.git
    pkgs.openssh
  ];
  opAccount = "my.1password.com";
  ghTokenItem = "t7mb2zeoupwwuigpbkjtz5uhwm";
  ghWith1Password = pkgs.writeShellScriptBin "gh" ''
    export PATH="${ghRuntimePath}:/usr/bin:/bin:/usr/sbin:/sbin"
    export OP_ACCOUNT="${opAccount}"
    ${pkgs._1password-cli}/bin/op signin >/dev/null
    export GH_TOKEN="$(${pkgs._1password-cli}/bin/op item get ${ghTokenItem} --fields token --reveal)"
    exec ${pkgs.gh}/bin/gh "$@"
  '';
in {
  programs._1password-shell-plugins = {
    enable = true;
    plugins = with pkgs; [awscli2 cachix];
    package = pkgs._1password-cli;
  };

  home.packages = [
    pkgs.gh
    #ghWith1Password disables due to anoying popups when running gh commands that require 1password auth, so we use the normal gh package instead
  ];
}
