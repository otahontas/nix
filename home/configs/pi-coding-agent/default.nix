{ pkgs, ... }:

let
  brave-search-skill = pkgs.buildNpmPackage {
    pname = "brave-search-skill";
    version = "1.0.0";

    src = ./skills/brave-search;

    npmDepsHash = "sha256-BQM1qKFB/CcCyyQqUnnCx3V2ZxDhC392nB4G2ZnjicQ=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };
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

      # Extensions
      ".pi/agent/extensions/notify.ts".source = ./extensions/notify.ts;
      ".pi/agent/extensions/rainbow-editor.ts".source = ./extensions/rainbow-editor.ts;

      # Skills
      ".pi/agent/skills/brave-search".source = brave-search-skill;
      ".pi/agent/skills/catch-up/SKILL.md".source = ./skills/catch-up/SKILL.md;
      ".pi/agent/skills/context-hunter/SKILL.md".source = ./skills/context-hunter/SKILL.md;
      ".pi/agent/skills/git-commit/SKILL.md".source = ./skills/git-commit/SKILL.md;
    };
  };

  programs.fish.shellAliases = {
    pic = "pi -c";
    pir = "pi -r";
  };
}
