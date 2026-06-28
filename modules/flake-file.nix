{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.flake-file.flakeModules.default
  ];

  flake-file = {
    description = "Multi-host Nix configuration for Darwin and NixOS";

    inputs.flake-file.url = "github:denful/flake-file";

    do-not-edit = lib.concatLines (
      map (line: "# ${line}") (
        lib.splitString "\n" ''
          This flake.nix file is auto-generated.
          The source of truth is merged from flake-parts modules under modules/.
          Each input is declared near the flake module that uses it.
          Regenerate with: nix run .#write-flake
          https://flake-file.denful.dev/''
      )
    );
  };
}
