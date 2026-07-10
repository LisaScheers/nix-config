{
  description = "Template for your HM homes and a handy generator for you `homeManagerConfiguration` calls.";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
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
