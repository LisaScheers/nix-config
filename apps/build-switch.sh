set -euo pipefail

flake_ref="${1:-.}"

case "${NIX_CONFIG_HOST_KIND}" in
  darwin)
    echo "Switching Darwin host ${NIX_CONFIG_DARWIN_HOST} for ${NIX_CONFIG_SYSTEM}" >&2
    exec sudo darwin-rebuild switch --flake "${flake_ref}#${NIX_CONFIG_DARWIN_HOST}"
    ;;
  nixos)
    echo "Switching NixOS host ${NIX_CONFIG_NIXOS_HOST} for ${NIX_CONFIG_SYSTEM}" >&2
    exec sudo nixos-rebuild switch --flake "${flake_ref}#${NIX_CONFIG_NIXOS_HOST}"
    ;;
  *)
    echo "No host switch is declared for ${NIX_CONFIG_SYSTEM}" >&2
    exit 1
    ;;
esac
