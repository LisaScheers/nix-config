{
  config,
  inputs,
  pkgs,
  ...
}: let
  stockKeeperPatch = ../../patches/stock-keeper-prisma-postgres.patch;
  stockKeeperSource = pkgs.applyPatches {
    name = "stock-keeper-source-prisma-pg";
    src = inputs.stock-keeper.outPath;
    patches = [stockKeeperPatch];
  };
  stockKeeperPackage = inputs.stock-keeper.packages.${pkgs.stdenv.hostPlatform.system}.stock-keeper.overrideAttrs (old: {
    patches = (old.patches or []) ++ [stockKeeperPatch];
    pnpmDeps = pkgs.fetchPnpmDeps {
      pname = "stock-keeper";
      version = "1.0.0";
      src = stockKeeperSource;
      hash = "sha256-QYi0kg1p4vfD0u9NU9J77IlOJ5mJs+yWeEb/9OjjD3E=";
      pnpmLockFile = "${stockKeeperSource}/pnpm-lock.yaml";
      fetcherVersion = 3;
    };

    buildPhase = ''
      runHook preBuild

      export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
      export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
      export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
      export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
      ./node_modules/.bin/prisma generate
      pnpm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/stock-keeper
      mkdir -p $out/bin

      cp -r app prisma public package.json pnpm-lock.yaml pnpm-workspace.yaml $out/lib/stock-keeper/
      cp -r node_modules $out/lib/stock-keeper/
      cp -r build $out/lib/stock-keeper/

      mkdir -p $out/lib/stock-keeper/prisma
      cp -r prisma/migrations $out/lib/stock-keeper/prisma/
      cp prisma/schema.prisma $out/lib/stock-keeper/prisma/
      cp prisma.config.ts $out/lib/stock-keeper/ 2>/dev/null || true

      cat > $out/bin/stock-keeper <<EOF
      #!${pkgs.bash}/bin/bash
      set -e
      export PATH="${pkgs.nodejs_22}/bin:${pkgs.openssl}/bin:\$PATH"
      export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
      export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
      export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
      export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
      cd $out/lib/stock-keeper

      if [ -z "\$PORT" ]; then
        export PORT=3000
      fi

      exec ./node_modules/.bin/react-router-serve ./build/server/index.js "\$@"
      EOF
      chmod +x $out/bin/stock-keeper

      cat > $out/bin/stock-keeper-setup <<EOF
      #!${pkgs.bash}/bin/bash
      set -e
      export PATH="${pkgs.nodejs_22}/bin:${pkgs.openssl}/bin:\$PATH"
      export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
      export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
      export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
      export PRISMA_FMT_BINARY="${pkgs.prisma-engines}/bin/prisma-fmt"
      cd $out/lib/stock-keeper

      if [ -z "\$DATABASE_URL" ]; then
        echo "Error: DATABASE_URL environment variable is not set or is empty" >&2
        exit 1
      fi

      if ! ./node_modules/.bin/prisma migrate deploy; then
        echo "" >&2
        echo "Migration deploy failed. Attempting to resolve the known failed migration as rolled back and retry." >&2
        echo "" >&2

        if ./node_modules/.bin/prisma migrate resolve --rolled-back 20240530213853_create_session_table 2>/dev/null; then
          ./node_modules/.bin/prisma migrate deploy
        else
          echo "Could not automatically resolve the migration. Please inspect Prisma migration state manually." >&2
          exit 1
        fi
      fi
      EOF
      chmod +x $out/bin/stock-keeper-setup

      runHook postInstall
    '';
  });
in {
  services.stock-keeper = {
    enable = true;
    package = stockKeeperPackage;
    # These will be overridden by environmentFile, but are required by the module
    shopifyApiKey = "placeholder-will-be-overridden-by-env-file";
    shopifyApiSecret = "placeholder-will-be-overridden-by-env-file";
    shopifyAppUrl = "https://stock-keeper.bylisa.dev";
    enablePostgres = true;
    enableNginx = true;
    nginxHost = "stock-keeper.bylisa.dev";
    nginxEnableSSL = true;
    environmentFile = "/run/secrets/stock-keeper-env";
  };

  sops.secrets = {
    "stock-keeper-env" = {
      sopsFile = ../../secrets/stock-keeper.env;
      owner = "stock-keeper";
      group = "stock-keeper";
      format = "dotenv";
    };
  };

  # Override nginx config to use wildcard certificate if available
  services.nginx.virtualHosts."stock-keeper.bylisa.dev" = {
    #useACMEHost = "wildcard.${config.networking.domain}";
    #forceSSL = true;
  };
}
