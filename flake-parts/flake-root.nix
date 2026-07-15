# --- flake-parts/flake-root.nix
{
  lib,
  inputs,
  ...
}: {
  # NOTE This is probably conflicting with https://github.com/srid/flake-root/
  # however it essentially fully replaces that functionality with a simple
  # option (thanks to the known structure) so it should be probably fine.
  options.flake-root = lib.mkOption {
    type = lib.types.path;
    description = ''
      Provides `config.flake-root` with the path to the flake root.
    '';
    default = ../.;
  };

  imports = [
    inputs.flake-file.flakeModules.nix-auto-follow
  ];

  # Build nix-auto-follow with each system's package set. The input follows the
  # unstable nixpkgs, which no longer evaluates on x86_64-darwin, while our
  # x86_64-darwin package set intentionally remains on nixpkgs 26.05.
  config.flake-file.prune-lock.program = lib.mkForce (
    pkgs: let
      nix-auto-follow = pkgs.callPackage (inputs.nix-auto-follow + "/derivation.nix") {};
    in
      pkgs.writeShellApplication {
        name = "nix-auto-follow";
        runtimeInputs = [nix-auto-follow];
        text = ''
          auto-follow "$1" > "$2"
        '';
      }
  );
}
