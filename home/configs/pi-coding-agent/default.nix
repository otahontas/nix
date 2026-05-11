{
  pkgs,
  lib,
  config,
  pi-mcp-adapter,
  pi-web-access,
  ...
}:

let
  # Pi coding agent - built from npm registry
  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = "0.72.1";

    src = ./pi-package;

    npmDepsHash = "sha256-wQI2D5lYJjjjib/OReZ0HBoWD8lQ3HY6Qls2w5qpb0s=";

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

  # Auto-discover extensions (.ts files and directories with index.ts)
  extensionEntries = builtins.readDir ./extensions;
  extensionSymlinks = builtins.listToAttrs (
    builtins.concatLists [
      # Single .ts files
      (map (name: {
        name = ".pi/agent/extensions/${name}";
        value = {
          source = ./extensions/${name};
        };
      }) (builtins.filter (name: lib.hasSuffix ".ts" name) (builtins.attrNames extensionEntries)))
      # Directories (extension subdirectories like subagent/)
      (map
        (name: {
          name = ".pi/agent/extensions/${name}";
          value = {
            source = ./extensions/${name};
          };
        })
        (
          builtins.filter (name: extensionEntries.${name} == "directory") (
            builtins.attrNames extensionEntries
          )
        )
      )
    ]
  );

  # Auto-discover agent definitions (.md files in agents/)
  agentFiles = builtins.filter (name: lib.hasSuffix ".md" name) (
    builtins.attrNames (builtins.readDir ./agents)
  );
  agentSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/agents/${name}";
      value = {
        source = ./agents/${name};
      };
    }) agentFiles
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
        export PATH="${pkgs.nodejs_24}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"

        # Load API keys from pass
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          GEMINI_API_KEY="$(${pkgs.pass}/bin/pass show api/gemini-pi-coding-agent-web-search 2>/dev/null || true)"
          ZAI_API_KEY="$(${pkgs.pass}/bin/pass show api/z-pi-coding-agent 2>/dev/null || true)"
          CONTEXT7_API_KEY="$(${pkgs.pass}/bin/pass show api/context7 2>/dev/null || true)"
          GITHITS_API_KEY="$(${pkgs.pass}/bin/pass show api/githits 2>/dev/null || true)"
          OPENCODE_GO_WORKSPACE_ID="$(${pkgs.pass}/bin/pass show api/opencode-go-workspace-id 2>/dev/null || true)"
          OPENCODE_GO_AUTH_COOKIE="$(${pkgs.pass}/bin/pass show api/opencode-go-auth-cookie 2>/dev/null || true)"
          export GEMINI_API_KEY ZAI_API_KEY CONTEXT7_API_KEY GITHITS_API_KEY OPENCODE_GO_WORKSPACE_ID OPENCODE_GO_AUTH_COOKIE
        fi
        exec ${pi-coding-agent}/bin/pi "$@"
      '')

      pkgs."poppler-utils"
    ];

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

      # Pi MCP adapter extension - built with deps
      ".pi/agent/extensions/pi-mcp-adapter".source = pi-mcp-adapter;

      # Pi web access extension - built with deps
      ".pi/agent/extensions/pi-web-access".source = pi-web-access;

      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;
    }
    // extensionSymlinks
    // agentSymlinks
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
