{ inputs }:
final: _prev:
let
  stockKeeperPatch = ./patches/stock-keeper-prisma-postgres.patch;
  stockKeeperSource = final.applyPatches {
    name = "stock-keeper-source-prisma-pg";
    src = inputs.stock-keeper.outPath;
    patches = [ stockKeeperPatch ];
  };
in
{
  stock-keeper =
    inputs.stock-keeper.packages.${final.stdenv.hostPlatform.system}.stock-keeper.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ stockKeeperPatch ];
        pnpmDeps = final.fetchPnpmDeps {
          pname = "stock-keeper";
          version = "1.0.0";
          src = stockKeeperSource;
          hash = "sha256-QYi0kg1p4vfD0u9NU9J77IlOJ5mJs+yWeEb/9OjjD3E=";
          pnpmLockFile = "${stockKeeperSource}/pnpm-lock.yaml";
          fetcherVersion = 3;
        };

        buildPhase = ''
          runHook preBuild

          export PRISMA_SCHEMA_ENGINE_BINARY="${final.prisma-engines}/bin/schema-engine"
          export PRISMA_QUERY_ENGINE_BINARY="${final.prisma-engines}/bin/query-engine"
          export PRISMA_QUERY_ENGINE_LIBRARY="${final.prisma-engines}/lib/libquery_engine.node"
          export PRISMA_FMT_BINARY="${final.prisma-engines}/bin/prisma-fmt"
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
          #!${final.bash}/bin/bash
          set -e
          export PATH="${final.nodejs_22}/bin:${final.openssl}/bin:\$PATH"
          export PRISMA_SCHEMA_ENGINE_BINARY="${final.prisma-engines}/bin/schema-engine"
          export PRISMA_QUERY_ENGINE_BINARY="${final.prisma-engines}/bin/query-engine"
          export PRISMA_QUERY_ENGINE_LIBRARY="${final.prisma-engines}/lib/libquery_engine.node"
          export PRISMA_FMT_BINARY="${final.prisma-engines}/bin/prisma-fmt"
          cd $out/lib/stock-keeper

          if [ -z "\$PORT" ]; then
            export PORT=3000
          fi

          exec ./node_modules/.bin/react-router-serve ./build/server/index.js "\$@"
          EOF
          chmod +x $out/bin/stock-keeper

          cat > $out/bin/stock-keeper-setup <<EOF
          #!${final.bash}/bin/bash
          set -e
          export PATH="${final.nodejs_22}/bin:${final.openssl}/bin:\$PATH"
          export PRISMA_SCHEMA_ENGINE_BINARY="${final.prisma-engines}/bin/schema-engine"
          export PRISMA_QUERY_ENGINE_BINARY="${final.prisma-engines}/bin/query-engine"
          export PRISMA_QUERY_ENGINE_LIBRARY="${final.prisma-engines}/lib/libquery_engine.node"
          export PRISMA_FMT_BINARY="${final.prisma-engines}/bin/prisma-fmt"
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
}
