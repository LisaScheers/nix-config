set -euo pipefail

flake_ref="${1:-.}"

case "${NIX_CONFIG_HOST_KIND}" in
  darwin)
    echo "Building Darwin host ${NIX_CONFIG_DARWIN_HOST} for ${NIX_CONFIG_SYSTEM}" >&2
    exec darwin-rebuild build --flake "${flake_ref}#${NIX_CONFIG_DARWIN_HOST}"
    ;;
  nixos)
    echo "Building NixOS host ${NIX_CONFIG_NIXOS_HOST} for ${NIX_CONFIG_SYSTEM}" >&2
    exec nixos-rebuild build --flake "${flake_ref}#${NIX_CONFIG_NIXOS_HOST}"
    ;;
  *)
    echo "No host build is declared for ${NIX_CONFIG_SYSTEM}" >&2
    exit 1
    ;;
esac
