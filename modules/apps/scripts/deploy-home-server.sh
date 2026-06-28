set -euo pipefail

source_dir="${1:-$PWD}"
target="${NIX_CONFIG_NIXOS_DEPLOY_TARGET}"
remote_dir="${NIX_CONFIG_NIXOS_DEPLOY_REMOTE_DIR}"
host="${NIX_CONFIG_NIXOS_HOST}"

if [ ! -d "$source_dir" ]; then
  echo "Source directory does not exist: $source_dir" >&2
  exit 1
fi

if [ ! -f "$source_dir/flake.nix" ]; then
  echo "Source directory does not look like this flake: $source_dir" >&2
  exit 1
fi

ssh_cmd=(ssh)
if [ -n "${SSHPASS:-}" ]; then
  ssh_cmd=(sshpass -e ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no)
fi

echo "Deploying $source_dir to $target:$remote_dir for NixOS host $host" >&2

tar \
  --exclude .git \
  --exclude .direnv \
  --exclude result \
  --exclude .DS_Store \
  -C "$source_dir" \
  -czf - . \
  | "${ssh_cmd[@]}" "$target" "rm -rf '$remote_dir' && mkdir -p '$remote_dir' && tar -xzf - -C '$remote_dir'"

"${ssh_cmd[@]}" "$target" "cd '$remote_dir' && sudo -n nixos-rebuild switch --flake path:'$remote_dir'#$host"
