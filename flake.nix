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
    comic-code-fonts = {
      url = "git+ssh://git@github.com/LisaScheers/comic-code-fonts.git?ref=main";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    flake-parts.url = "https://flakehub.com/f/hercules-ci/flake-parts/0.1.*";
    flake-parts-builder = {
      url = "github:tsandrini/flake-parts-builder";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
      };
    };
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
    lix-nixos-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shop-empty-track = {
      url = "git+ssh://git@github.com/LisaScheers/shop-empty-track.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/0.1.*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stock-keeper = {
      url = "git+ssh://git@github.com/LisaScheers/stock-keeper.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
