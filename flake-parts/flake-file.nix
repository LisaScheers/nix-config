{ lib, ... }: {
  flake-file = {
    description = "Multi-host Nix configuration for Darwin and NixOS";

    do-not-edit = lib.concatLines (
      map (line: "# ${line}") (
        lib.splitString "\n" ''
          This flake.nix file is auto-generated.
          The source of truth is merged from flake-parts modules under flake-parts/.
          Regenerate with: nix run .#write-flake
          https://flake-file.denful.dev/''
      )
    );
  };
}
