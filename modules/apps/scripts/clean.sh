set -euo pipefail

if [ "$#" -eq 0 ]; then
  set -- --delete-older-than "${NIX_CONFIG_GC_AGE}"
fi

echo "Running Nix garbage collection on ${NIX_CONFIG_SYSTEM}: nix-collect-garbage $*" >&2
exec nix-collect-garbage "$@"
