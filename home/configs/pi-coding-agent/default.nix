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
    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      --profile-directory="Profile 5" "$@"
  '';
  mcpConfig = pkgs.writeText "pi-mcp.json" (
    builtins.replaceStrings
      [ "@chromeExecutable@" ]
      [ "${pkgs.google-chrome}/bin/google-chrome-stable" ]
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
  installUiShSkills = pkgs.writeShellApplication {
    name = "install-ui-sh-skills";
    runtimeInputs = [
      config.programs.password-store.package
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      token="$(pass show api/uidotsh)"

      fetch() {
        curl --fail --silent --show-error \
          --header @<(printf 'Authorization: Bearer %s\n' "$token") \
          --header 'Accept: application/json' \
          "$1"
      }

      index="$(fetch https://ui.sh/api/skills)"
      jq --exit-status '
        .skills | type == "array" and
        all(.[]; .name | type == "string" and test("^[a-z0-9-]+$"))
      ' <<< "$index" >/dev/null

      while IFS= read -r -d "" skill; do
        response="$(fetch "https://ui.sh/api/skills/$skill")"
        jq --exit-status --arg skill "$skill" '
          .name == $skill and
          (.files | type == "object") and
          all(.files | to_entries[];
            (.key | type == "string") and
            (.value | type == "string")
          )
        ' <<< "$response" >/dev/null

        while IFS= read -r -d "" file; do
          case "$file" in
            "" | /* | . | */. | .. | ../* | */.. | */../*)
              printf 'Invalid ui.sh skill path: %s\n' "$file" >&2
              exit 1
              ;;
          esac

          target="$HOME/.agents/skills/$skill/$file"
          mkdir -p "''${target%/*}"
          jq --join-output --arg file "$file" '.files[$file]' <<< "$response" > "$target"
        done < <(jq --join-output '.files | keys[] | ., "\u0000"' <<< "$response")
      done < <(jq --join-output '.skills[].name | ., "\u0000"' <<< "$index")

      printf 'Installed %s ui.sh skills.\n' "$(jq '.skills | length' <<< "$index")"
    '';
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

  # Agent definitions come from pi-subagents package (advisor, context-builder, delegate, oracle, planner, researcher, reviewer, scout, worker).

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
    }
    // extensionSymlinks
    // skillSymlinks
    // promptSymlinks;

    # Activation script to merge settings into settings.json
    # This preserves all other settings managed by pi itself
    activation = {
      installUiShSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${installUiShSkills}/bin/install-ui-sh-skills
      '';
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
