set -euo pipefail

flake_ref="${1:-.}"

echo "Updating flake inputs for ${flake_ref}" >&2
exec nix flake update "${flake_ref}"
