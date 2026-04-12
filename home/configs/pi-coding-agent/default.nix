{
  pkgs,
  lib,
  config,
  pi-mcp-adapter,
  ...
}:

let
  # Pi coding agent - built from npm registry
  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = "0.64.0";

    src = ./pi-package;

    npmDepsHash = "sha256-OCg/AwFBC/NG3JCweMur+VuqChc92/C1cngfidXd5ag=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r node_modules $out/lib/node_modules
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js $out/bin/pi

      # Patch agent-session.js: unlimited 429 retries + capped backoff
      TARGET=$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/core/agent-session.js

      # 1. Skip maxRetries cap for 429/rate-limit errors
      substituteInPlace "$TARGET" \
        --replace-fail 'if (this._retryAttempt > settings.maxRetries) {' \
        'const _is429 = /429|rate.?limit|too many requests/i.test(message.errorMessage || ""); if (!_is429 && this._retryAttempt > settings.maxRetries) {'

      # 2. Cap delay at maxDelayMs (set to 900000/15min in settings.json)
      substituteInPlace "$TARGET" \
        --replace-fail 'const delayMs = settings.baseDelayMs * 2 ** (this._retryAttempt - 1);' \
        'const delayMs = Math.min(settings.baseDelayMs * 2 ** (this._retryAttempt - 1), settings.maxDelayMs);'

      runHook postInstall
    '';
  };

  # lat.md CLI - Agent Lattice knowledge graph
  lat-md = pkgs.buildNpmPackage {
    pname = "lat-md";
    version = "0.11.0";

    src = ./lat-md-package;

    npmDepsHash = "sha256-gGRPqE7hWv51Zd5Sv5hOcepZToZfl1G/3FPLRrBSnko=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r node_modules $out/lib/node_modules
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/lat.md/dist/src/cli/index.js $out/bin/lat
      runHook postInstall
    '';
  };

  # Auto-discover extensions (.ts files)
  extensionFiles = builtins.filter (name: lib.hasSuffix ".ts" name) (
    builtins.attrNames (builtins.readDir ./extensions)
  );
  extensionSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/extensions/${name}";
      value = {
        source = ./extensions/${name};
      };
    }) extensionFiles
  );

  # Auto-discover simple skills (no deps) - symlink entire directories
  skillDirs = builtins.attrNames (builtins.readDir ./skills);
  skillSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/skills/${name}";
      value = {
        source = ./skills/${name};
      };
    }) skillDirs
  );

  # Auto-discover prompt templates (.md files in prompts/)
  promptFiles = builtins.filter (name: lib.hasSuffix ".md" name) (
    builtins.attrNames (builtins.readDir ./prompts)
  );
  promptSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/prompts/${name}";
      value = {
        source = ./prompts/${name};
      };
    }) promptFiles
  );

in

{
  home = {
    packages = [
      (pkgs.writeShellScriptBin "work-tickets" (builtins.readFile ./scripts/work-tickets.sh))

      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:${pkgs."poppler-utils"}/bin:${pkgs.ast-grep}/bin:${lat-md}/bin:$PATH"

        # Load API keys from pass
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          export ZAI_API_KEY="$(${pkgs.pass}/bin/pass show api/z-pi-coding-agent 2>/dev/null || true)"
          export FIRECRAWL_API_KEY="$(${pkgs.pass}/bin/pass show api/firecrawl 2>/dev/null || true)"
          export CONTEXT7_API_KEY="$(${pkgs.pass}/bin/pass show api/context7 2>/dev/null || true)"
          export GITHITS_API_KEY="$(${pkgs.pass}/bin/pass show api/githits 2>/dev/null || true)"
        fi
        exec ${pi-coding-agent}/bin/pi "$@"
      '')

      pkgs."poppler-utils"
    ];

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

      # Pi MCP adapter extension - built with deps
      ".pi/agent/extensions/pi-mcp-adapter".source = pi-mcp-adapter;

      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;
    }
    // extensionSymlinks
    // skillSymlinks
    // promptSymlinks;

    # Activation script to merge settings into settings.json
    # This preserves all other settings managed by pi itself
    activation = {
      mergeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash ${./merge-settings.sh} ${./settings.json}
      '';

      # Clean up redundant extension deps (pi's jiti resolves these internally)
      cleanExtensionDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ext_dir="$HOME/.pi/agent/extensions"
        for f in "$ext_dir/package.json" "$ext_dir/package-lock.json"; do
          [ -f "$f" ] && run rm "$f"
        done
        [ -d "$ext_dir/node_modules" ] && run rm -rf "$ext_dir/node_modules"
      '';
    };
  };

  launchd.agents.pi-session-indexer = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${./scripts/build-session-index.sh}"
      ];
      StartInterval = 7200;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
      ProcessType = "Background";
      LowPriorityIO = true;
    };
  };

  programs = {
    fish.shellAliases = {
      pic = "pi -c";
      pir = "pi -r";
    };

    # Catppuccin theme (follows global catppuccin.flavor)
    pi.catppuccin.enable = true;
  };
}
