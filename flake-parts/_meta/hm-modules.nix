{
  description = "Basic template for custom home-manager modules.";

  inputs = {
    home-manager = {
      url = "github:LisaScheers/home-manager/agent/nushell-session-environment";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  extraTrustedPublicKeys = [ ];
  extraSubstituters = [ ];
}
