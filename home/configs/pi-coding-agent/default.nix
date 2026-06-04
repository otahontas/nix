{
  pkgs,
  lib,
  config,
  system,
  pi-nix,
  ...
}:

let
  piPackage = pi-nix.packages.${system}.coding-agent;
  gitSigningKey = config.programs.git.signing.key;

  piGitGpg = pkgs.writeShellScriptBin "pi-git-gpg" ''
    parent="$(/bin/ps -p "$PPID" -o comm= 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '[:space:]')"
    parent="''${parent##*/}"

    if [ "$parent" != "git" ]; then
      echo "gpg is only available to git in pi" >&2
      exit 127
    fi

    if [ "$#" -eq 3 ] \
      && [ "$1" = "--status-fd=2" ] \
      && [ "$2" = "-bsau" ] \
      && [ "$3" = "${gitSigningKey}" ]; then
      exec ${pkgs.gnupg}/bin/gpg "$@"
    fi

    for arg in "$@"; do
      if [ "$arg" = "--verify" ]; then
        exec ${pkgs.gnupg}/bin/gpg "$@"
      fi
    done

    echo "gpg is only available for git signing and signature verification in pi" >&2
    exit 127
  '';

  piCommandBlockers = pkgs.runCommand "pi-command-blockers" { } ''
    mkdir -p "$out/bin"

    {
      echo '#!/bin/sh'
      echo 'echo "pass is not available to pi" >&2'
      echo 'exit 127'
    } > "$out/bin/pass"
    chmod +x "$out/bin/pass"

    ln -s ${piGitGpg}/bin/pi-git-gpg "$out/bin/gpg"
  '';

  piWrapper = pkgs.writeShellScriptBin "pi" ''
    # Load API keys from pass before pi starts. Do not add pass to pi's runtime PATH.
    pass_cmd="$(command -v pass 2>/dev/null || true)"
    if [ -n "$pass_cmd" ]; then
      read_secret() {
        ${pkgs.coreutils}/bin/timeout 2 "$pass_cmd" show "$1" 2>/dev/null || true
      }

      GEMINI_API_KEY="$(read_secret api/gemini-pi-coding-agent-web-search)"
      CONTEXT7_API_KEY="$(read_secret api/context7)"
      GITHITS_API_KEY="$(read_secret api/githits)"
      UIDOTSH_TOKEN="$(read_secret api/uidotsh)"
      export GEMINI_API_KEY CONTEXT7_API_KEY GITHITS_API_KEY UIDOTSH_TOKEN
      unset -f read_secret
      unset pass_cmd
    fi

    export PATH="${piCommandBlockers}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"
    exec ${piPackage}/bin/pi "$@"
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

  # Agent definitions come from pi-subagents package (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate).

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
      pkgs."poppler-utils"
    ];

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

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
