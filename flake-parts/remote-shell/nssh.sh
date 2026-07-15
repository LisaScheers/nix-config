usage() {
  cat >&2 <<'EOF'
usage: nssh [SSH connection/authentication options] [-A] destination

nssh is only for interactive shells. Use ssh for remote commands, tunnels,
subsystems, or custom multiplexing.
EOF
}

die() {
  echo "nssh: $*" >&2
  exit 2
}

connection_args=()
forward_agent=0
destination=

while [ "$#" -gt 0 ]; do
  case "$1" in
    -A)
      forward_agent=1
      shift
      ;;
    -a)
      forward_agent=0
      shift
      ;;
    -4|-6|-C|-K|-k|-q|-v|-vv|-vvv)
      connection_args+=("$1")
      shift
      ;;
    -B|-b|-c|-E|-e|-F|-I|-i|-J|-l|-m|-p)
      [ "$#" -ge 2 ] || die "$1 requires an argument"
      connection_args+=("$1" "$2")
      shift 2
      ;;
    -o)
      [ "$#" -ge 2 ] || die "-o requires an argument"
      option_name=${2%%=*}
      option_name=${option_name%%[[:space:]]*}
      option_name=$(printf '%s' "$option_name" | tr '[:upper:]' '[:lower:]')
      case "$option_name" in
        controlmaster|controlpath|controlpersist|remotecommand|requesttty|sessiontype|localcommand|permitlocalcommand|forwardagent|clearallforwardings|localforward|remoteforward|dynamicforward)
          die "SSH option $option_name is incompatible; use ordinary ssh"
          ;;
      esac
      connection_args+=("$1" "$2")
      shift 2
      ;;
    -N|-T|-W|-s|-M|-S|-O|-f|-L|-R|-D|-w|-X|-Y|-G)
      die "$1 is incompatible; use ordinary ssh"
      ;;
    --)
      shift
      [ "$#" -gt 0 ] || die "missing destination"
      destination=$1
      shift
      break
      ;;
    -*)
      die "unsupported SSH option: $1"
      ;;
    *)
      destination=$1
      shift
      break
      ;;
  esac
done

[ -n "$destination" ] || {
  usage
  exit 2
}
[ "$#" -eq 0 ] || die "remote commands are not supported; use ordinary ssh"

control_dir=$(mktemp -d /tmp/nssh.XXXXXXXX)
control_socket="$control_dir/master"
remote_dir=
master_started=0

cleanup() {
  status=${1:-$?}
  trap - EXIT HUP INT TERM
  if [ "$master_started" -eq 1 ]; then
    if [ -n "$remote_dir" ]; then
      "$BYLISA_SSH" "${connection_args[@]}" -S "$control_socket" -o ControlMaster=no -o RemoteCommand=none -T -a "$destination" "chmod -R u+w '$remote_dir' 2>/dev/null || true; rm -rf '$remote_dir'" >/dev/null 2>&1 || true
    fi
    "$BYLISA_SSH" -S "$control_socket" -O exit "$destination" >/dev/null 2>&1 || true
  fi
  rm -rf "$control_dir"
  exit "$status"
}
trap 'cleanup $?' EXIT
trap 'cleanup 129' HUP
trap 'cleanup 130' INT
trap 'cleanup 143' TERM

# This script is expanded by the remote POSIX shell, not by this Bash process.
# shellcheck disable=SC2016
probe_script='set -eu
for candidate in /tmp/bylisa-shell.*; do
  [ -d "$candidate" ] || continue
  if [ -f "$candidate/.pid" ]; then
    pid=$(cat "$candidate/.pid" 2>/dev/null || true)
    case "$pid" in
      *[!0-9]*|"") ;;
      *) kill -0 "$pid" 2>/dev/null || { chmod -R u+w "$candidate" 2>/dev/null || true; rm -rf "$candidate"; } ;;
    esac
  elif find "$candidate" -prune -mtime +0 -print 2>/dev/null | grep -q .; then
    chmod -R u+w "$candidate" 2>/dev/null || true
    rm -rf "$candidate"
  fi
done
session=$(mktemp -d /tmp/bylisa-shell.XXXXXXXX)
chmod 700 "$session"
uname -s
uname -m
printf "%s\n" "$session"'

mapfile -t probe < <(
  "$BYLISA_SSH" "${connection_args[@]}" -M -S "$control_socket" \
    -o ControlMaster=yes -o ControlPersist=60 -o ClearAllForwardings=yes \
    -o RemoteCommand=none -o RequestTTY=no -T -a "$destination" "$probe_script"
)
master_started=1

[ "${#probe[@]}" -eq 3 ] || die "remote platform probe returned invalid data"
case "${probe[0]}:${probe[1]}" in
  Linux:aarch64|Linux:arm64) target=aarch64-linux ;;
  Linux:x86_64|Linux:amd64) target=x86_64-linux ;;
  Darwin:arm64|Darwin:aarch64) target=aarch64-darwin ;;
  Darwin:x86_64|Darwin:amd64) target=x86_64-darwin ;;
  *) die "unsupported remote platform: ${probe[0]}/${probe[1]}" ;;
esac
remote_dir=${probe[2]}
case "$remote_dir" in
  /tmp/bylisa-shell.*) ;;
  *) die "remote returned an unsafe session path" ;;
esac

bundle="$BYLISA_ARTIFACTS/bundles/$BYLISA_ARTIFACT_VERSION/$target.tar.gz"
expected=$(awk -v file="$target.tar.gz" '$2 == file { print $1 }' "$BYLISA_ARTIFACTS/bundles/$BYLISA_ARTIFACT_VERSION/SHA256SUMS")
[ -n "$expected" ] || die "missing checksum for $target"
actual=$(sha256sum "$bundle" | awk '{print $1}')
[ "$actual" = "$expected" ] || die "local bundle checksum mismatch"

"$BYLISA_SSH" "${connection_args[@]}" -S "$control_socket" -o ControlMaster=no \
  -o RemoteCommand=none -o RequestTTY=no -T -a "$destination" \
  "tar -xzf - -C '$remote_dir'" <"$bundle"

final_agent=(-a)
if [ "$forward_agent" -eq 1 ]; then
  final_agent=(-A)
fi

"$BYLISA_SSH" "${connection_args[@]}" -S "$control_socket" -o ControlMaster=no \
  -o RemoteCommand=none -tt "${final_agent[@]}" "$destination" "'$remote_dir/run.sh'"
