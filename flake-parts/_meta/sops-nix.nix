{
  description = "sops-nix flake part";

  inputs = {
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  extraTrustedPublicKeys = [ ];
  extraSubstituters = [ ];
}
