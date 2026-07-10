# --- flake-parts/overlays/default.nix
{ inputs, ... }:
let
  codex = final: _prev: {
    codex = inputs.codex-cli-nix.packages.${final.stdenv.hostPlatform.system}.default;
  };

  # Nushell's integration tests assume a full TTY/shell nesting; they fail
  # on Darwin Nix builds with EPERM / wrong SHLVL (see env.rs SHLVL checks).
  nushell = _final: prev: {
    nushell =
      if prev.stdenv.hostPlatform.isDarwin then
        prev.nushell.overrideAttrs (_old: {
          doCheck = false;
        })
      else
        prev.nushell;
  };

  stockKeeper = import ./stock-keeper.nix { inherit inputs; };

  default = final: prev: (codex final prev) // (nushell final prev) // (stockKeeper final prev);
in
{
  flake.overlays = {
    inherit codex default nushell;
    stock-keeper = stockKeeper;
  };

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ default ];
      config.allowUnfree = true;
    };
  };

  flake-file.inputs.codex-cli-nix = {
    url = "github:sadjow/codex-cli-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
