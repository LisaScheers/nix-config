{
  description = "Template for your HM homes and a handy generator for you `homeManagerConfiguration` calls.";

  inputs = {
    home-manager = {
      url = "github:LisaScheers/home-manager/agent/nushell-session-environment";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    onepassword-shell-plugins = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:1Password/shell-plugins";
    };
  };
  extraTrustedPublicKeys = [];
  extraSubstituters = [];
}
