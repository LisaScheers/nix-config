# --- flake-parts/overlays/default.nix
{inputs, ...}: let
  codex = final: _prev: {
    codex = inputs.codex-cli-nix.packages.${final.stdenv.hostPlatform.system}.default;
  };

  # Nushell's integration tests assume a full TTY/shell nesting; they fail
  # on Darwin Nix builds with EPERM / wrong SHLVL (see env.rs SHLVL checks).
  nushell = _final: prev: {
    nushell =
      if prev.stdenv.hostPlatform.isDarwin
      then
        prev.nushell.overrideAttrs (_old: {
          doCheck = false;
        })
      else prev.nushell;
  };

  default = final: prev: (codex final prev) // (nushell final prev);
in {
  flake.overlays = {
    inherit codex default nushell;
  };

  perSystem = {system, ...}: let
    nixpkgsSource =
      if system == "x86_64-darwin"
      then
        builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/3860155d3bdb870027d96373fa8d7a423b8809de.tar.gz";
          sha256 = "1ghsr1qq5lqhj1d1q9li1x97377079gyg0j6dwj83xg30362ksgn";
        }
      else inputs.nixpkgs;
  in {
    _module.args.pkgs = import nixpkgsSource {
      inherit system;
      overlays = [default];
      config.allowUnfree = true;
    };
  };

  flake-file.inputs.codex-cli-nix = {
    url = "github:sadjow/codex-cli-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
