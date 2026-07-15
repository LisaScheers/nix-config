#!/bin/sh
set -eu

version='@version@'
base_url="https://shell.bylisa.dev/bundles/$version"

detect_target() {
  os=$(uname -s)
  arch=$(uname -m)
  case "$os:$arch" in
    Linux:aarch64|Linux:arm64) echo aarch64-linux ;;
    Linux:x86_64|Linux:amd64) echo x86_64-linux ;;
    Darwin:arm64|Darwin:aarch64) echo aarch64-darwin ;;
    Darwin:x86_64|Darwin:amd64) echo x86_64-darwin ;;
    *)
      echo "bylisa-shell: unsupported platform: $os/$arch" >&2
      return 1
      ;;
  esac
}

expected_hash() {
  case "$1" in
    aarch64-linux) echo '@hash_aarch64_linux@' ;;
    x86_64-linux) echo '@hash_x86_64_linux@' ;;
    aarch64-darwin) echo '@hash_aarch64_darwin@' ;;
    x86_64-darwin) echo '@hash_x86_64_darwin@' ;;
    *) return 1 ;;
  esac
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  else
    echo "bylisa-shell: sha256sum, shasum, or openssl is required" >&2
    return 1
  fi
}

download() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$2" "$1"
  else
    echo "bylisa-shell: curl or wget is required" >&2
    return 1
  fi
}

main() {
  if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
    echo "bylisa-shell: a controlling terminal is required" >&2
    return 1
  fi

  target=$(detect_target)
  session_root=$(mktemp -d /tmp/bylisa-shell.XXXXXXXX)
  chmod 700 "$session_root"
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

  archive="$session_root/bundle.tar.gz"
  download "$base_url/$target.tar.gz" "$archive"
  actual=$(hash_file "$archive")
  expected=$(expected_hash "$target")
  if [ "$actual" != "$expected" ]; then
    echo "bylisa-shell: bundle checksum mismatch" >&2
    return 1
  fi

  tar -xzf "$archive" -C "$session_root"
  rm -f "$archive"
  "$session_root/run.sh" "$@"
}

main "$@" </dev/tty >/dev/tty 2>&1
