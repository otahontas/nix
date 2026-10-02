{
  pkgs,
  lib,
  config,
  system,
  githits-cli,
  pi-nix,
  otahontas-nixpkgs,
  ...
}:

let
  piPackage = pi-nix.packages.${system}.coding-agent;
  piLatMd = otahontas-nixpkgs.packages.${system}.lat-md;
  piPlannotator = otahontas-nixpkgs.packages.${system}.plannotator;
  plannotatorBrowser = pkgs.writeShellScript "plannotator-browser" ''
    exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "$@"
  '';
  mcpConfig = pkgs.writeText "pi-mcp.json" (
    builtins.replaceStrings
      [ "@chromeExecutable@" ]
      [ "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]
      (builtins.readFile ./mcp.json)
  );
  sessionIndexer = pkgs.writeShellApplication {
    name = "pi-session-indexer";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      findutils
      jq
      ripgrep
    ];
    text = builtins.readFile ./scripts/build-session-index.sh;
  };
  piWrapper = pkgs.writeShellScriptBin "pi" ''
    # Load API keys from pass before pi starts.
    pass_cmd="$(command -v pass 2>/dev/null || true)"
    if [ -n "$pass_cmd" ]; then
      read_secret() {
        "$pass_cmd" show "$1" 2>/dev/null || true
      }

      GEMINI_API_KEY="$(read_secret api/gemini-pi-coding-agent-web-search)"
      CONTEXT7_API_KEY="$(read_secret api/context7)"
      GITHITS_API_TOKEN="$(read_secret api/githits)"
      LAT_LLM_KEY="$(read_secret api/lat-md)"
      export GEMINI_API_KEY CONTEXT7_API_KEY GITHITS_API_TOKEN LAT_LLM_KEY
      unset -f read_secret
      unset pass_cmd
    fi

    unset PLANNOTATOR_BROWSER
    export PONYTAIL_DEFAULT_MODE=ultra
    export BROWSER="${plannotatorBrowser}"
    export PATH="${piLatMd}/bin:${piPlannotator}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"
    exec ${piPackage}/bin/pi "$@"
  '';

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

  # Agent definitions come from the pi-subagents package.

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
    packages = [ piLatMd ];

    file = {
      ".agents/skills/githits-mcp/SKILL.md".source = githits-cli + "/skills/githits-mcp/SKILL.md";
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;
      ".pi/agent/APPEND_SYSTEM.md".source = ./sources/APPEND_SYSTEM.md;
      ".pi/agent/mcp.json".source = mcpConfig;
      ".pi/agent/models.json".source = ./models.json;
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
    };
  };

  launchd.agents.pi-session-indexer = {
    enable = true;
    config = {
      ProgramArguments = [
        "${sessionIndexer}/bin/pi-session-indexer"
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
    pi = {
      # Catppuccin theme (follows global catppuccin.flavor)
      catppuccin.enable = true;
      coding-agent = {
        enable = true;
        package = piWrapper;
      };
    };
  };
}
