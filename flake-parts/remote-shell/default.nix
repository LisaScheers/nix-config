{
  inputs,
  lib,
  ...
}: let
  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];
  supportedSystemsExpression = "[ ${lib.concatMapStringsSep " " builtins.toJSON supportedSystems} ]";
  version = "${builtins.substring 0 12 inputs.nixpkgs.rev}-4";
  x86DarwinNixpkgs = {
    rev = "3860155d3bdb870027d96373fa8d7a423b8809de";
    lastModified = 1784025883;
    narHash = "sha256-9ukpzADj9YEkb0aC51864JxxUg+RJhxakBDTgnHIGr4=";
  };
  starshipConfig = ../homes + "/lisa@vega/starship.toml";
  portableLock = {
    version = 7;
    root = "root";
    nodes = {
      root.inputs = {
        nixpkgs = "nixpkgs";
        nixpkgs-x86-darwin = "nixpkgs-x86-darwin";
      };
      nixpkgs = {
        locked = {
          inherit (inputs.nixpkgs) lastModified narHash rev;
          owner = "NixOS";
          repo = "nixpkgs";
          type = "github";
        };
        original = {
          owner = "NixOS";
          repo = "nixpkgs";
          rev = inputs.nixpkgs.rev;
          type = "github";
        };
      };
      nixpkgs-x86-darwin = {
        locked =
          x86DarwinNixpkgs
          // {
            owner = "NixOS";
            repo = "nixpkgs";
            type = "github";
          };
        original = {
          inherit (x86DarwinNixpkgs) rev;
          owner = "NixOS";
          repo = "nixpkgs";
          type = "github";
        };
      };
    };
  };
  portableFlake = ''
    {
      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/${inputs.nixpkgs.rev}";
        nixpkgs-x86-darwin.url = "github:NixOS/nixpkgs/${x86DarwinNixpkgs.rev}";
      };

      outputs = { nixpkgs, nixpkgs-x86-darwin, ... }: let
        systems = ${supportedSystemsExpression};
        forAllSystems = nixpkgs.lib.genAttrs systems;
        packageFor = system: let
          source = if system == "x86_64-darwin" then nixpkgs-x86-darwin else nixpkgs;
          pkgs = import source { inherit system; config.allowUnfree = true; };
        in pkgs.callPackage ./profile.nix { starshipConfig = ./starship.toml; };
      in {
        packages = forAllSystems (system: {
          remote-shell = packageFor system;
          default = packageFor system;
        });
        apps = forAllSystems (system: {
          remote-shell = {
            type = "app";
            program = "''${packageFor system}/bin/bylisa-shell";
          };
          default = {
            type = "app";
            program = "''${packageFor system}/bin/bylisa-shell";
          };
        });
      };
    }
  '';
in {
  perSystem = {pkgs, ...}: let
    remoteShell = pkgs.callPackage ./profile.nix {inherit starshipConfig;};
    portableSource = pkgs.runCommand "bylisa-shell-source-${version}" {} ''
      mkdir -p "$out"
      cp ${pkgs.writeText "flake.nix" portableFlake} "$out/flake.nix"
      cp ${pkgs.writeText "flake.lock" (builtins.toJSON portableLock)} "$out/flake.lock"
      cp ${./profile.nix} "$out/profile.nix"
      cp ${./launcher.sh} "$out/launcher.sh"
      cp ${./config.nu} "$out/config.nu"
      cp ${./env.nu} "$out/env.nu"
      cp ${./gitconfig} "$out/gitconfig"
      cp ${starshipConfig} "$out/starship.toml"
    '';
    nixPortable = {
      aarch64-linux = pkgs.fetchurl {
        url = "https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-aarch64";
        hash = "sha256-r0HY3v25+hfuNhIg7gWgx1jT5iMThKP5aaMU+RM3ROo=";
      };
      x86_64-linux = pkgs.fetchurl {
        url = "https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64";
        hash = "sha256-tAnFWQTJCaw67aP7ElMxn4aond0boxpd7DPUoGQUxyo=";
      };
    };
    linuxPkgs = lib.genAttrs ["aarch64-linux" "x86_64-linux"] (
      targetSystem:
        import inputs.nixpkgs {
          system = targetSystem;
        }
    );
    artifacts =
      pkgs.runCommand "bylisa-shell-artifacts-${version}" {
        nativeBuildInputs = [
          pkgs.coreutils
          pkgs.gnutar
          pkgs.gzip
        ];
      } ''
        mkdir -p "$out/bundles/${version}"
        build_bundle() {
          target="$1"
          portable="$2"
          bash="$3"
          work="$TMPDIR/$target"
          mkdir -p "$work/source"
          cp -R ${portableSource}/. "$work/source/"
          substitute ${./run.sh} "$work/run.sh" --subst-var-by target "$target"
          chmod 700 "$work/run.sh"
          if [ -n "$portable" ]; then
            cp "$portable" "$work/nix-portable"
            chmod 700 "$work/nix-portable"
            cp "$bash/bin/bash" "$work/bash"
            chmod 700 "$work/bash"
          fi
          tar --sort=name --mtime=@1 --owner=0 --group=0 --numeric-owner -C "$work" -cf - . \
            | gzip -n >"$out/bundles/${version}/$target.tar.gz"
        }

        build_bundle aarch64-linux ${nixPortable.aarch64-linux} ${linuxPkgs.aarch64-linux.pkgsStatic.bash}
        build_bundle x86_64-linux ${nixPortable.x86_64-linux} ${linuxPkgs.x86_64-linux.pkgsStatic.bash}
        build_bundle aarch64-darwin "" ""
        build_bundle x86_64-darwin "" ""

        cd "$out/bundles/${version}"
        sha256sum ./*.tar.gz | sed 's# \./# #' >SHA256SUMS
        hash_aarch64_linux=$(awk '$2 == "aarch64-linux.tar.gz" { print $1 }' SHA256SUMS)
        hash_x86_64_linux=$(awk '$2 == "x86_64-linux.tar.gz" { print $1 }' SHA256SUMS)
        hash_aarch64_darwin=$(awk '$2 == "aarch64-darwin.tar.gz" { print $1 }' SHA256SUMS)
        hash_x86_64_darwin=$(awk '$2 == "x86_64-darwin.tar.gz" { print $1 }' SHA256SUMS)
        substitute ${./bootstrap.sh} "$out/bootstrap.sh" \
          --subst-var-by version ${lib.escapeShellArg version} \
          --subst-var hash_aarch64_linux \
          --subst-var hash_x86_64_linux \
          --subst-var hash_aarch64_darwin \
          --subst-var hash_x86_64_darwin
        chmod 555 "$out/bootstrap.sh"
      '';
    nssh = pkgs.writeShellApplication {
      name = "nssh";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.gawk
        pkgs.openssh
      ];
      text = ''
        export BYLISA_SSH="''${BYLISA_SSH:-${lib.getExe pkgs.openssh}}"
        export BYLISA_ARTIFACTS=${artifacts}
        export BYLISA_ARTIFACT_VERSION=${lib.escapeShellArg version}

        ${builtins.readFile ./nssh.sh}
      '';
      meta = {
        description = "Enter the ephemeral bylisa.dev Nix shell over SSH";
        mainProgram = "nssh";
        platforms = lib.platforms.unix;
      };
    };
    artifactAudit =
      pkgs.runCommand "bylisa-shell-artifact-audit" {
        nativeBuildInputs = [
          pkgs.coreutils
          pkgs.diffutils
          pkgs.gnugrep
          pkgs.gnutar
          pkgs.gzip
        ];
      } ''
                for archive in ${artifacts}/bundles/${version}/*.tar.gz; do
                  tar -tzf "$archive" >listing
                  cat >expected <<'EOF'
        ./
        ./run.sh
        ./source/
        ./source/config.nu
        ./source/env.nu
        ./source/flake.lock
        ./source/flake.nix
        ./source/gitconfig
        ./source/launcher.sh
        ./source/profile.nix
        ./source/starship.toml
        EOF
          case "$archive" in
            *-linux.tar.gz)
              echo ./bash >>expected
              echo ./nix-portable >>expected
              ;;
                  esac
                  sort -o listing listing
                  sort -o expected expected
                  diff -u expected listing
                  if grep -E '(\.age$|(^|/)secrets?/|(^|/)\.ssh/|OP_[A-Z_]+)' listing; then
                    echo "secret-bearing path found in $archive" >&2
                    exit 1
                  fi
                  tar -xzf "$archive" -C "$TMPDIR"
                  if grep -R -E '(OP_[A-Z_]+|op://|1[Pp]assword|age\.secrets)' "$TMPDIR/source"; then
                    echo "secret reference found in $archive" >&2
                    exit 1
                  fi
          rm -rf "$TMPDIR/source" "$TMPDIR/run.sh" "$TMPDIR/bash" "$TMPDIR/nix-portable" listing
                done
                touch "$out"
      '';
    profileSmoke =
      pkgs.runCommand "bylisa-shell-profile-smoke" {
        nativeBuildInputs = [remoteShell];
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME" "$TMPDIR/provided-session"
        output=$(BYLISA_SHELL_SESSION_DIR="$TMPDIR/provided-session" bylisa-shell --command '
          for command in [git htop tree rg jq starship] {
            if (which $command | is-empty) { error make { msg: $"missing ($command)" } }
          }
          git --version | ignore
          htop --version | ignore
          tree --version | ignore
          rg --version | ignore
          jq --version | ignore
          starship --version | ignore
          if ((git config --global user.name) != "Lisa Scheers") {
            error make { msg: "ephemeral Git identity is missing" }
          }
          if $env.GIT_CONFIG_NOSYSTEM != "1" {
            error make { msg: "system Git configuration is not isolated" }
          }
          print $env.HOME
          print $env.GIT_CONFIG_GLOBAL
          print $env.XDG_CONFIG_HOME
          print $env.XDG_CACHE_HOME
          print $env.XDG_DATA_HOME
          print $env.XDG_STATE_HOME
        ')
        echo "$output" | grep -F "$HOME"
        echo "$output" | grep -F '/provided-session/session/config/gitconfig'
        echo "$output" | grep -F '/provided-session/session/config'
        echo "$output" | grep -F '/provided-session/session/cache'
        echo "$output" | grep -F '/provided-session/session/data'
        echo "$output" | grep -F '/provided-session/session/state'
        test ! -e "$TMPDIR/provided-session/session"
        touch "$out"
      '';
    fakeSsh = pkgs.writeShellScript "nssh-fake-ssh" ''
      printf '%s\n' "$*" >>"$NSSH_TEST_LOG"
      case " $* " in
        *" -M "*)
          case "''${NSSH_TEST_PLATFORM:-linux}" in
            linux) printf 'Linux\nx86_64\n%s\n' "''${NSSH_TEST_REMOTE_DIR:-/tmp/bylisa-shell.test}" ;;
            linux-arm) printf 'Linux\naarch64\n%s\n' "''${NSSH_TEST_REMOTE_DIR:-/tmp/bylisa-shell.test}" ;;
            darwin) printf 'Darwin\narm64\n%s\n' "''${NSSH_TEST_REMOTE_DIR:-/tmp/bylisa-shell.test}" ;;
            darwin-x86) printf 'Darwin\nx86_64\n%s\n' "''${NSSH_TEST_REMOTE_DIR:-/tmp/bylisa-shell.test}" ;;
            unsupported) printf 'Plan9\nmips\n%s\n' "''${NSSH_TEST_REMOTE_DIR:-/tmp/bylisa-shell.test}" ;;
          esac
          ;;
        *"tar -xzf -"*)
          cat >"''${NSSH_TEST_CAPTURE:-/dev/null}"
          if [ "''${NSSH_TEST_UPLOAD_FAIL:-0}" -eq 1 ]; then
            exit 23
          fi
          ;;
        *" -tt "*"/run.sh"*) sleep "''${NSSH_TEST_FINAL_DELAY:-0}" ;;
        *) ;;
      esac
    '';
    nsshTransportTest =
      pkgs.runCommand "nssh-transport-test" {
        nativeBuildInputs = [
          nssh
          pkgs.diffutils
          pkgs.gnugrep
        ];
      } ''
        if nssh example uptime; then
          echo 'nssh accepted a remote command' >&2
          exit 1
        fi
        if nssh -L 8022:localhost:22 example; then
          echo 'nssh accepted a tunnel' >&2
          exit 1
        fi
        if nssh -o 'LocalForward 8022 localhost 22' example; then
          echo 'nssh accepted a spaced forwarding option' >&2
          exit 1
        fi
        if nssh -o ControlMaster=auto example; then
          echo 'nssh accepted caller multiplexing' >&2
          exit 1
        fi

        export NSSH_TEST_LOG="$TMPDIR/without-agent.log"
        BYLISA_SSH=${fakeSsh} nssh -p 2222 -i test-key example
        grep -F -- '-p 2222 -i test-key' "$NSSH_TEST_LOG"
        grep -E -- '-M .* -a example' "$NSSH_TEST_LOG"
        grep -E -- '-tt -a example .*/run.sh' "$NSSH_TEST_LOG"
        grep -F -- "rm -rf '/tmp/bylisa-shell.test'" "$NSSH_TEST_LOG"
        grep -F -- '-O exit example' "$NSSH_TEST_LOG"
        grep -F -- 'kill -0 "$pid"' "$NSSH_TEST_LOG"
        grep -F -- 'find "$candidate" -prune -mtime +0' "$NSSH_TEST_LOG"

        export NSSH_TEST_LOG="$TMPDIR/with-agent.log"
        BYLISA_SSH=${fakeSsh} nssh -A example
        grep -E -- '-M .* -a example' "$NSSH_TEST_LOG"
        grep -E -- '-tt -A example .*/run.sh' "$NSSH_TEST_LOG"

        check_mapping() {
          platform="$1"
          target="$2"
          export NSSH_TEST_LOG="$TMPDIR/map-$target.log"
          export NSSH_TEST_CAPTURE="$TMPDIR/map-$target.tar.gz"
          NSSH_TEST_PLATFORM="$platform" BYLISA_SSH=${fakeSsh} nssh example
          cmp "$NSSH_TEST_CAPTURE" ${artifacts}/bundles/${version}/"$target.tar.gz"
          unset NSSH_TEST_CAPTURE
        }
        check_mapping linux x86_64-linux
        check_mapping linux-arm aarch64-linux
        check_mapping darwin aarch64-darwin
        check_mapping darwin-x86 x86_64-darwin

        export NSSH_TEST_LOG="$TMPDIR/failed-upload.log"
        if NSSH_TEST_UPLOAD_FAIL=1 BYLISA_SSH=${fakeSsh} nssh example; then
          echo 'nssh accepted a failed upload' >&2
          exit 1
        fi
        grep -F -- "rm -rf '/tmp/bylisa-shell.test'" "$NSSH_TEST_LOG"
        grep -F -- '-O exit example' "$NSSH_TEST_LOG"

        export NSSH_TEST_LOG="$TMPDIR/unsupported.log"
        if NSSH_TEST_PLATFORM=unsupported BYLISA_SSH=${fakeSsh} nssh example; then
          echo 'nssh accepted an unsupported platform' >&2
          exit 1
        fi
        grep -F -- '-O exit example' "$NSSH_TEST_LOG"

        export NSSH_TEST_LOG="$TMPDIR/concurrent.log"
        NSSH_TEST_FINAL_DELAY=1 NSSH_TEST_REMOTE_DIR=/tmp/bylisa-shell.concurrent-one BYLISA_SSH=${fakeSsh} nssh example &
        first=$!
        NSSH_TEST_FINAL_DELAY=1 NSSH_TEST_REMOTE_DIR=/tmp/bylisa-shell.concurrent-two BYLISA_SSH=${fakeSsh} nssh example &
        second=$!
        wait "$first"
        wait "$second"
        test "$(grep -oE '/tmp/nssh\.[^ /]+/master' "$NSSH_TEST_LOG" | sort -u | wc -l)" -eq 2
        while read -r socket; do
          test ! -e "''${socket%/master}"
        done < <(grep -oE '/tmp/nssh\.[^ /]+/master' "$NSSH_TEST_LOG" | sort -u)
        grep -F -- "rm -rf '/tmp/bylisa-shell.concurrent-one'" "$NSSH_TEST_LOG"
        grep -F -- "rm -rf '/tmp/bylisa-shell.concurrent-two'" "$NSSH_TEST_LOG"

        export NSSH_TEST_LOG="$TMPDIR/signal.log"
        NSSH_TEST_FINAL_DELAY=2 BYLISA_SSH=${fakeSsh} nssh example &
        signaled=$!
        for _attempt in $(seq 1 100); do
          grep -q -- '-tt' "$NSSH_TEST_LOG" 2>/dev/null && break
          sleep 0.02
        done
        kill -TERM "$signaled"
        if wait "$signaled"; then
          echo 'nssh returned success after SIGTERM' >&2
          exit 1
        fi
        grep -F -- "rm -rf '/tmp/bylisa-shell.test'" "$NSSH_TEST_LOG"
        grep -F -- '-O exit example' "$NSSH_TEST_LOG"
        touch "$out"
      '';
  in {
    packages = {
      inherit nssh;
      remote-shell = remoteShell;
      remote-shell-artifacts = artifacts;
    };
    apps.remote-shell = {
      type = "app";
      program = "${remoteShell}/bin/bylisa-shell";
    };
    checks = {
      remote-shell-artifacts = artifactAudit;
      remote-shell-profile = profileSmoke;
      nssh-transport = nsshTransportTest;
    };
  };

  flake.homeModules.remote-shell = {
    config,
    inputs,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.programs.nssh;
  in {
    options.programs.nssh.enable = lib.mkEnableOption "the ephemeral remote Nix shell launcher";
    config = lib.mkIf cfg.enable {
      home.packages = [inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.nssh];
    };
  };
}
