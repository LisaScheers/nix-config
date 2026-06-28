# This flake.nix file is auto-generated.
# The source of truth is merged from flake-parts modules under modules/.
# Each input is declared near the flake module that uses it.
# Regenerate with: nix run .#write-flake
# https://flake-file.denful.dev/
{
  description = "Multi-host Nix configuration for Darwin and NixOS";

  outputs = inputs: import ./outputs.nix inputs;

  inputs = {
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.*";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    import-tree = {
      url = "github:vic/import-tree";
      flake = false;
    };
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    nixpkgs-authentik.url = "github:LisaScheers/nixpkgs/5105c5e9cf1a92c4888ede41a2e8deb733282feb";
    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shop-empty-track = {
      url = "github:LisaScheers/shop-empty-track/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stock-keeper = {
      url = "github:LisaScheers/stock-keeper/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
