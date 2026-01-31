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

  # Auto-discover extensions (.ts files)
  # Extensions to keep source but not install
  disabledExtensions = [
    "agents-md-auto-revise.ts"
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
    "agents-md-improver"
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
    packages = [
      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:$PATH"

        # Load Brave Search API key if available
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          export BRAVE_API_KEY="$(${pkgs.pass}/bin/pass show api/brave-search 2>/dev/null || true)"
        fi

        exec npx @mariozechner/pi-coding-agent "$@"
      '')
    ];

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

      # Skills with deps - built separately
      ".pi/agent/skills/brave-search".source = brave-search-skill;
    }
    // extensionSymlinks
    // skillSymlinks;

    # Activation script to merge enabledModels into settings.json
    # This preserves all other settings managed by pi itself
    activation = {
      mergeEnabledModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash ${./merge-enabled-models.sh} ${./enabled-models.json}
      '';
    };
  };

  programs = {
    fish.shellAliases = {
      pic = "pi -c";
      pir = "pi -r";
    };

    # Catppuccin theme (follows global catppuccin.flavor)
    pi.catppuccin.enable = true;
    pi.piception.enable = true;
  };
}
