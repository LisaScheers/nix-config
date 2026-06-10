{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.services.autoSyncUpdate;
  hasLaunchd = options ? launchd;
  hasSystemd = options ? systemd;
  defaultRebuildCommand =
    if hasLaunchd
    then ["/run/current-system/sw/bin/darwin-rebuild" "switch"]
    else ["/run/current-system/sw/bin/nixos-rebuild" "switch"];
  rebuildCommand = lib.concatMapStringsSep " " lib.escapeShellArg cfg.rebuildCommand;
  script = pkgs.writeShellApplication {
    name = "nix-auto-sync-update";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.git
      pkgs.nix
    ];
    text = ''
      set -euo pipefail

      repo_path=${lib.escapeShellArg cfg.repositoryPath}
      flake_host=${lib.escapeShellArg cfg.flakeHost}
      branch=${lib.escapeShellArg cfg.branch}
      env_file="''${AUTO_SYNC_ENV_FILE:-${lib.escapeShellArg cfg.environmentFile}}"
      lock_dir=${lib.escapeShellArg cfg.lockDirectory}
      email_to=${lib.escapeShellArg cfg.emailTo}
      log_file="$(mktemp)"
      lock_acquired=0

      # shellcheck disable=SC2329
      cleanup() {
        rm -f "$log_file"
        if [ -n "''${askpass_file:-}" ]; then
          rm -f "$askpass_file"
        fi
        if [ -n "''${mail_file:-}" ]; then
          rm -f "$mail_file"
        fi
        if [ "$lock_acquired" -eq 1 ]; then
          rmdir "$lock_dir" 2>/dev/null || true
        fi
      }
      trap cleanup EXIT

      if ! mkdir "$lock_dir" 2>/dev/null; then
        echo "Another nix-auto-sync-update run is active; exiting."
        exit 0
      fi
      lock_acquired=1

      load_env() {
        if [ -f "$env_file" ]; then
          set -a
          # shellcheck disable=SC1090
          . "$env_file"
          set +a
        fi
      }

      configure_git_auth() {
        git_args=(-c "safe.directory=$repo_path")

        if [ -n "''${AUTO_SYNC_GIT_AUTH_HEADER:-}" ]; then
          git_args+=(-c "http.extraHeader=$AUTO_SYNC_GIT_AUTH_HEADER")
        fi

        if [ -n "''${AUTO_SYNC_GIT_TOKEN:-}" ]; then
          askpass_file="$(mktemp)"
          chmod 700 "$askpass_file"
          cat > "$askpass_file" <<'EOF'
      #!/bin/sh
      case "$1" in
        *Username*) printf '%s\n' "''${AUTO_SYNC_GIT_USERNAME:-x-access-token}" ;;
        *Password*) printf '%s\n' "''${AUTO_SYNC_GIT_TOKEN}" ;;
        *) printf '\n' ;;
      esac
      EOF
          export GIT_ASKPASS="$askpass_file"
          export GIT_TERMINAL_PROMPT=0
        fi
      }

      send_failure_mail() {
        status="$1"

        if [ -z "''${AUTO_SYNC_SMTP_URL:-}" ]; then
          echo "AUTO_SYNC_SMTP_URL is not set; cannot send watchdog email." >&2
          return 0
        fi

        mail_from="''${AUTO_SYNC_SMTP_FROM:-nix-auto-sync-update@$(/bin/hostname -f 2>/dev/null || /bin/hostname)}"
        mail_to="''${AUTO_SYNC_SMTP_TO:-$email_to}"
        mail_file="$(mktemp)"

        {
          printf 'From: %s\r\n' "$mail_from"
          printf 'To: %s\r\n' "$mail_to"
          printf 'Subject: [watchdog] nix auto-sync-update failed on %s\r\n' "$flake_host"
          printf 'Content-Type: text/plain; charset=UTF-8\r\n'
          printf '\r\n'
          printf 'nix-auto-sync-update failed on %s with exit status %s.\n\n' "$flake_host" "$status"
          printf 'Repository: %s\n' "$repo_path"
          printf 'Branch: %s\n\n' "$branch"
          printf 'Captured output:\n'
          cat "$log_file"
        } > "$mail_file"

        curl_args=(
          --fail
          --show-error
          --silent
          --url "$AUTO_SYNC_SMTP_URL"
          --mail-from "$mail_from"
          --mail-rcpt "$mail_to"
          --upload-file "$mail_file"
        )

        if [ "''${AUTO_SYNC_SMTP_REQUIRE_TLS:-1}" != "0" ]; then
          curl_args+=(--ssl-reqd)
        fi

        if [ -n "''${AUTO_SYNC_SMTP_USERNAME:-}" ] || [ -n "''${AUTO_SYNC_SMTP_PASSWORD:-}" ]; then
          curl_args+=(--user "''${AUTO_SYNC_SMTP_USERNAME:-}:''${AUTO_SYNC_SMTP_PASSWORD:-}")
        fi

        if ! curl "''${curl_args[@]}"; then
          echo "Failed to send watchdog email." >&2
        fi
      }

      run_update() {
        load_env
        configure_git_auth

        if [ ! -d "$repo_path/.git" ]; then
          if [ -z "''${AUTO_SYNC_GIT_REPOSITORY_URL:-}" ]; then
            echo "$repo_path is not a git checkout and AUTO_SYNC_GIT_REPOSITORY_URL is not set." >&2
            return 1
          fi

          mkdir -p "$(dirname "$repo_path")"
          git "''${git_args[@]}" clone --branch "$branch" "$AUTO_SYNC_GIT_REPOSITORY_URL" "$repo_path"
        fi

        cd "$repo_path"
        git "''${git_args[@]}" fetch --prune origin "$branch"
        if git show-ref --verify --quiet "refs/heads/$branch"; then
          git "''${git_args[@]}" checkout "$branch"
        else
          git "''${git_args[@]}" checkout --track -b "$branch" "origin/$branch"
        fi
        git "''${git_args[@]}" merge --ff-only "origin/$branch"

        rebuild_cmd=(${rebuildCommand})
        "''${rebuild_cmd[@]}" --flake "path:$repo_path#$flake_host"
      }

      if run_update > >(tee -a "$log_file") 2>&1; then
        exit 0
      else
        status=$?
        send_failure_mail "$status"
        exit "$status"
      fi
    '';
  };
in {
  options.services.autoSyncUpdate = {
    enable = lib.mkEnableOption "automatic repository sync and host rebuild";

    flakeHost = lib.mkOption {
      type = lib.types.str;
      description = "Flake output host name to switch after the repository is pulled.";
    };

    repositoryPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nix-darwin";
      description = "Local checkout path for this repository.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch to fast-forward and apply.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nix-auto-sync-update.env";
      description = "Optional shell-style environment file containing Git and SMTP credentials.";
    };

    emailTo = lib.mkOption {
      type = lib.types.str;
      default = "lisa@scheers.tech";
      description = "Default watchdog email recipient.";
    };

    intervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 300;
      description = "Number of seconds between sync attempts.";
    };

    lockDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/run/nix-auto-sync-update.lock";
      description = "Runtime lock directory used to prevent overlapping runs.";
    };

    rebuildCommand = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultRebuildCommand;
      description = "Command used to switch the host after pulling the repository.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.optionalAttrs hasSystemd {
      systemd.services.nix-auto-sync-update = {
        description = "Pull this Nix repository and apply host changes";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe script;
        };
      };

      systemd.timers.nix-auto-sync-update = {
        description = "Run nix-auto-sync-update every five minutes";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnActiveSec = "${toString cfg.intervalSeconds}s";
          OnUnitActiveSec = "${toString cfg.intervalSeconds}s";
          AccuracySec = "30s";
          Unit = "nix-auto-sync-update.service";
        };
      };
    }
    // lib.optionalAttrs hasLaunchd {
      launchd.daemons.nix-auto-sync-update.serviceConfig = {
        Label = "tech.scheers.nix-auto-sync-update";
        ProgramArguments = [(lib.getExe script)];
        RunAtLoad = false;
        StartInterval = cfg.intervalSeconds;
        StandardOutPath = "/var/log/nix-auto-sync-update.log";
        StandardErrorPath = "/var/log/nix-auto-sync-update.log";
      };
    }
  );
}
