#!/usr/bin/env bash
set -euo pipefail

host="${NIX_DARWIN_HOST:-Vega}"
repo_url="${NIX_DARWIN_REPO_URL:-https://github.com/LisaScheers/nix-darwin.git}"
branch="${NIX_DARWIN_BRANCH:-main}"
target_dir="${NIX_DARWIN_TARGET_DIR:-/private/etc/nix-darwin}"
nix_installer_url="${NIX_INSTALLER_URL:-https://nixos.org/nix/install}"
switch_system=1

usage() {
  cat <<EOF
Usage: $0 [options]

Bootstraps this nix-darwin repository onto a fresh macOS machine.

Options:
  --host HOST          Flake host to install. Default: ${host}
  --repo URL           Git repository to clone. Default: ${repo_url}
  --branch BRANCH      Git branch to check out. Default: ${branch}
  --target DIR         Local checkout path. Default: ${target_dir}
  --build-only         Build the host but do not switch.
  -h, --help           Show this help.

Environment overrides:
  NIX_DARWIN_HOST
  NIX_DARWIN_REPO_URL
  NIX_DARWIN_BRANCH
  NIX_DARWIN_TARGET_DIR
  NIX_INSTALLER_URL
EOF
}

log() {
  printf '==> %s\n' "$*" >&2
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      [ "$#" -ge 2 ] || fail "--host requires a value"
      host="$2"
      shift 2
      ;;
    --repo)
      [ "$#" -ge 2 ] || fail "--repo requires a value"
      repo_url="$2"
      shift 2
      ;;
    --branch)
      [ "$#" -ge 2 ] || fail "--branch requires a value"
      branch="$2"
      shift 2
      ;;
    --target)
      [ "$#" -ge 2 ] || fail "--target requires a value"
      target_dir="$2"
      shift 2
      ;;
    --build-only)
      switch_system=0
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

if [ "$(uname -s)" != "Darwin" ]; then
  fail "this installer only supports macOS"
fi

if [ "$(id -u)" -eq 0 ]; then
  fail "run this as the target user, not as root"
fi

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  log "installing Xcode Command Line Tools"
  /usr/bin/xcode-select --install || true
  fail "finish the Xcode Command Line Tools installer, then rerun this script"
fi

if ! command -v git >/dev/null 2>&1; then
  fail "git is not available after Xcode Command Line Tools installation"
fi

if ! command -v curl >/dev/null 2>&1; then
  fail "curl is required"
fi

if ! command -v nix >/dev/null 2>&1; then
  log "installing upstream Nix for bootstrap"
  nix_extra_conf="$(mktemp /tmp/nix-bootstrap-conf.XXXXXX)"
  trap 'rm -f "${nix_extra_conf:-}"' EXIT
  cat > "$nix_extra_conf" <<'EOF'
experimental-features = nix-command flakes
EOF
  curl --proto '=https' --tlsv1.2 -sSf -L "$nix_installer_url" | sh -s -- --daemon --yes --no-channel-add --nix-extra-conf-file "$nix_extra_conf"
fi

if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

command -v nix >/dev/null 2>&1 || fail "nix is not available; open a new terminal and rerun this script"

if [ ! -d "$target_dir/.git" ]; then
  if [ -e "$target_dir" ] && [ "$(find "$target_dir" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" != "0" ]; then
    fail "$target_dir exists and is not an empty git checkout"
  fi

  log "creating checkout at $target_dir"
  sudo mkdir -p "$target_dir"
  sudo chown "$(id -un):$(id -gn)" "$target_dir"
  git clone --branch "$branch" "$repo_url" "$target_dir"
else
  log "updating checkout at $target_dir"
  git -C "$target_dir" fetch --prune origin "$branch"
  git -C "$target_dir" checkout "$branch"
  git -C "$target_dir" merge --ff-only "origin/$branch"
fi

sudo git config --global --add safe.directory "$target_dir" >/dev/null 2>&1 || true

log "building nix-darwin host $host"
nix develop "$target_dir" --command darwin-rebuild build --flake "$target_dir#$host"

if [ "$switch_system" -eq 0 ]; then
  log "build-only requested; not switching"
  exit 0
fi

log "switching nix-darwin host $host"
nix develop "$target_dir" --command sudo darwin-rebuild switch --flake "$target_dir#$host"

log "installation complete for $host; the configured Nix implementation is now managed by nix-darwin"
