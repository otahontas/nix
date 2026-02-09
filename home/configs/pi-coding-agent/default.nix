{ pkgs, lib, ... }:

let
  # Skills with npm dependencies need to be built
  brave-search-skill = pkgs.buildNpmPackage {
    pname = "brave-search-skill";
    version = "1.0.0";

    src = ./skills-with-deps/brave-search;

    npmDepsHash = "sha256-BQM1qKFB/CcCyyQqUnnCx3V2ZxDhC392nB4G2ZnjicQ=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  piSessionsBackup = pkgs.writeShellScriptBin "pi-sessions-backup" ''
    set -euo pipefail

    src_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/sessions"
    icloud_root="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
    host_name="$(
      /usr/sbin/scutil --get LocalHostName 2>/dev/null || ${pkgs.coreutils}/bin/hostname -s
    )"
    dest_dir="$icloud_root/pi-sessions/$host_name"

    if [ ! -d "$icloud_root" ]; then
      echo "iCloud Drive path not found: $icloud_root" >&2
      exit 1
    fi

    if [ ! -d "$src_dir" ]; then
      echo "pi sessions directory not found: $src_dir" >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$dest_dir"

    extra_flags=()
    if [ "''${1:-}" = "--dry-run" ]; then
      extra_flags+=(--dry-run)
    fi

    exec ${pkgs.rsync}/bin/rsync -a --exclude ".DS_Store" "''${extra_flags[@]}" "$src_dir/" "$dest_dir/"
  '';

  # Auto-discover extensions (.ts files)
  # Extensions to keep source but not install
  disabledExtensions = [
    "agents-md-auto-revise.ts"
    "context-for-editor.ts"
    "double-shot-latte.ts"
    "nvim-bridge.ts"
    "piception.ts"
    "ralph-loop.ts"
  ];
  extensionFiles = builtins.filter (
    name: lib.hasSuffix ".ts" name && !builtins.elem name disabledExtensions
  ) (builtins.attrNames (builtins.readDir ./extensions));
  extensionSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/extensions/${name}";
      value = {
        source = ./extensions/${name};
      };
    }) extensionFiles
  );

  # Auto-discover simple skills (no deps) - symlink entire directories
  # Skills to keep source but not install
  disabledSkills = [
    "address-reviews"
    "agents-md-improver"
    "branch-review"
    "catch-up"
    "code-simplifier"
    "context-hunter"
    "feature-dev"
    "pr-review-toolkit"
    "sequential-agent-execution"
  ];
  skillDirs = builtins.filter (name: !builtins.elem name disabledSkills) (
    builtins.attrNames (builtins.readDir ./skills)
  );
  skillSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/skills/${name}";
      value = {
        source = ./skills/${name};
      };
    }) skillDirs
  );
in

{
  home = {
    # Install pi package with Node.js wrapper
    # TODO: pin @mariozechner/pi-coding-agent to an explicit version in Nix instead of runtime npx resolution.
    packages = [
      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:$PATH"

        # Load Brave Search API key if available
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          export BRAVE_API_KEY="$(${pkgs.pass}/bin/pass show api/brave-search 2>/dev/null || true)"
        fi

        exec npx @mariozechner/pi-coding-agent "$@"
      '')

      # Opt-in pi instance that syncs with Neovim via the nvim bridge extension.
      (pkgs.writeShellScriptBin "pinvim" ''
        export PATH="${pkgs.nodejs_24}/bin:$PATH"

        # Load Brave Search API key if available
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          export BRAVE_API_KEY="$(${pkgs.pass}/bin/pass show api/brave-search 2>/dev/null || true)"
        fi

        exec npx @mariozechner/pi-coding-agent -e "$HOME/.pi/agent/extensions-opt/nvim-bridge.ts" "$@"
      '')

      piSessionsBackup
    ];

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

      # Skills with deps - built separately
      ".pi/agent/skills/brave-search".source = brave-search-skill;

      # Opt-in extensions (not auto-discovered)
      ".pi/agent/extensions-opt/nvim-bridge.ts".source = ./extensions/nvim-bridge.ts;
    }
    // extensionSymlinks
    // skillSymlinks;

    # Activation script to merge settings into settings.json
    # This preserves all other settings managed by pi itself
    activation = {
      mergeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash ${./merge-settings.sh} ${./settings.json}
      '';
    };
  };

  launchd.agents.pi-sessions-backup = {
    enable = true;
    config = {
      Label = "com.otahontas.pi-sessions-backup";
      ProgramArguments = [ "${piSessionsBackup}/bin/pi-sessions-backup" ];
      StartInterval = 86400;
      RunAtLoad = true;
      StandardOutPath = "/Users/otahontas/Library/Logs/pi-sessions-backup.log";
      StandardErrorPath = "/Users/otahontas/Library/Logs/pi-sessions-backup.log";
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
