{
  description = "Provides `config.flake-root` variable pointing to the root of the flake project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-file.url = "github:denful/flake-file";
  };
  extraTrustedPublicKeys = [];
  extraSubstituters = [];
}
