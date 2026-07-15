session_root=${BYLISA_SHELL_SESSION_DIR:-}
owns_session_root=0
if [ -z "$session_root" ]; then
  session_root=$(mktemp -d "${TMPDIR:-/tmp}/bylisa-shell.XXXXXXXX")
  owns_session_root=1
fi

chmod 700 "$session_root"
state_root="$session_root/session"
config_root="$state_root/config"
mkdir -p "$config_root/nushell" "$state_root/cache" "$state_root/data" "$state_root/state"
chmod 700 "$state_root" "$config_root" "$config_root/nushell" "$state_root/cache" "$state_root/data" "$state_root/state"

cleanup() {
  if [ "$owns_session_root" -eq 1 ]; then
    rm -rf "$session_root"
  else
    rm -rf "$state_root"
  fi
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

install -m 600 "$BYLISA_CONFIG_TEMPLATE" "$config_root/nushell/config.nu"
install -m 600 "$BYLISA_ENV_TEMPLATE" "$config_root/nushell/env.nu"
install -m 600 "$BYLISA_GIT_CONFIG_TEMPLATE" "$config_root/gitconfig"
install -m 600 "$BYLISA_STARSHIP_CONFIG_TEMPLATE" "$config_root/starship.toml"
starship init nu >"$config_root/nushell/starship.nu"
chmod 600 "$config_root/nushell/starship.nu"

export XDG_CONFIG_HOME="$config_root"
export XDG_CACHE_HOME="$state_root/cache"
export XDG_DATA_HOME="$state_root/data"
export XDG_STATE_HOME="$state_root/state"
export GIT_CONFIG_GLOBAL="$config_root/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export GIT_ATTR_NOSYSTEM=1
export STARSHIP_CONFIG="$config_root/starship.toml"
export NU_CONFIG_DIR="$config_root/nushell"
export TERMINFO_DIRS="$BYLISA_TERMINFO${TERMINFO_DIRS:+:$TERMINFO_DIRS}"

case "${1:-}" in
  "")
    if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
      echo "bylisa-shell: an interactive terminal is required" >&2
      exit 1
    fi
    nu --config "$config_root/nushell/config.nu" --env-config "$config_root/nushell/env.nu"
    ;;
  --command)
    shift
    if [ "$#" -eq 0 ]; then
      echo "bylisa-shell: --command requires a Nushell command" >&2
      exit 2
    fi
    nu --config "$config_root/nushell/config.nu" --env-config "$config_root/nushell/env.nu" --commands "$*"
    ;;
  *)
    echo "usage: bylisa-shell [--command NUSHELL_COMMAND]" >&2
    exit 2
    ;;
esac
