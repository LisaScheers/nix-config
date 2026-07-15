#!/bin/sh
set -eu

CDPATH=''
export CDPATH
session_root=$(cd "$(dirname "$0")" && pwd)
printf '%s\n' "$$" >"$session_root/.pid"

cleanup() {
  chmod -R u+w "$session_root" 2>/dev/null || true
  rm -rf "$session_root"
}
terminate() {
  status=$1
  trap - EXIT HUP INT TERM
  cleanup
  exit "$status"
}
trap cleanup EXIT
trap 'terminate 129' HUP
trap 'terminate 130' INT
trap 'terminate 143' TERM

export BYLISA_SHELL_SESSION_DIR="$session_root"
target='@target@'

case "$target" in
  aarch64-linux|x86_64-linux)
    chmod 700 "$session_root/nix-portable"
    export NP_LOCATION="$session_root/nix-portable-state"
    export NP_RUNTIME=proot
    chmod 700 "$session_root/bash"
    "$session_root/bash" "$session_root/nix-portable" nix --extra-experimental-features 'nix-command flakes' run "path:$session_root/source#remote-shell" -- "$@"
    ;;
  aarch64-darwin|x86_64-darwin)
    if ! command -v nix >/dev/null 2>&1; then
      echo "bylisa-shell: Darwin targets require an existing Nix installation" >&2
      exit 1
    fi
    nix --extra-experimental-features 'nix-command flakes' run "path:$session_root/source#remote-shell" -- "$@"
    ;;
  *)
    echo "bylisa-shell: unsupported target: $target" >&2
    exit 1
    ;;
esac
