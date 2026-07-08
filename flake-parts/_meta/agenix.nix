{
  description = "Agenix flake part";
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };
  extraTrustedPublicKeys = [];
  extraSubstituters = [];
}
