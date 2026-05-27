{
  pkgs,
  lib,
  config,
  pi-mcp-adapter,
  pi-web-access,
  pi-subagents,
  pi-ralph-loop,
  ...
}:

let
  inherit (pkgs) pi-coding-agent;

  piNodeAliases = pkgs.runCommand "pi-node-aliases" { } ''
    mkdir -p $out/node_modules/@earendil-works

    piRoot=$(find ${pi-coding-agent}/lib/node_modules -mindepth 1 -maxdepth 1 -type d | head -n1)
    piNodeModules="$piRoot/node_modules"

    makeAlias() {
      target="$1"
      package="$2"
      aliasDir="$out/node_modules/@earendil-works/$package"

      mkdir -p "$aliasDir"
      ln -s "$target/dist" "$aliasDir/dist"
      printf '{"name":"@earendil-works/%s","type":"module","main":"./dist/index.js","types":"./dist/index.d.ts"}\n' "$package" > "$aliasDir/package.json"
    }

    makeAlias "$piRoot" pi-coding-agent

    for package in pi-ai pi-agent-core pi-tui; do
      if [ -e "$piNodeModules/@earendil-works/$package" ]; then
        makeAlias "$piNodeModules/@earendil-works/$package" "$package"
      elif [ -e "$piNodeModules/@mariozechner/$package" ]; then
        makeAlias "$piNodeModules/@mariozechner/$package" "$package"
      fi
    done
  '';

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

  # Agent definitions now come from pi-subagents package (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate)
  # Custom agents can be added to ./agents/ directory — auto-discovered and symlinked to ~/.pi/agent/agents/
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
      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"
        export NODE_PATH="${piNodeAliases}/node_modules''${NODE_PATH:+:$NODE_PATH}"

        # Load API keys from pass
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          GEMINI_API_KEY="$(${pkgs.pass}/bin/pass show api/gemini-pi-coding-agent-web-search 2>/dev/null || true)"
          CONTEXT7_API_KEY="$(${pkgs.pass}/bin/pass show api/context7 2>/dev/null || true)"
          GITHITS_API_KEY="$(${pkgs.pass}/bin/pass show api/githits 2>/dev/null || true)"
          OPENCODE_GO_WORKSPACE_ID="$(${pkgs.pass}/bin/pass show api/opencode-go-workspace-id 2>/dev/null || true)"
          OPENCODE_GO_AUTH_COOKIE="$(${pkgs.pass}/bin/pass show api/opencode-go-auth-cookie 2>/dev/null || true)"
          export GEMINI_API_KEY CONTEXT7_API_KEY GITHITS_API_KEY OPENCODE_GO_WORKSPACE_ID OPENCODE_GO_AUTH_COOKIE
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

      # pi-subagents extension - multi-agent orchestration
      ".pi/agent/extensions/pi-subagents".source = pi-subagents;

      # pi-ralph-loop extension - autonomous coding loops
      ".pi/agent/extensions/pi-ralph-loop".source = pi-ralph-loop;

      # pi-ralph-loop skills
      ".pi/agent/skills/ralph-loop".source = "${pi-ralph-loop}/skills/ralph-loop";
      ".pi/agent/skills/ralph-draft".source = "${pi-ralph-loop}/skills/ralph-draft";
      ".pi/agent/skills/ralph-finalize".source = "${pi-ralph-loop}/skills/ralph-finalize";

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
