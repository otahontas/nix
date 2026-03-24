{
  pkgs,
  lib,
  pi-mcp-adapter,
  pi-web-access,
  ...
}:

let
  piVersion = "0.62.0";

  # Pi coding agent - built from npm registry
  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = piVersion;

    src = ./pi-package;

    npmDepsHash = "sha256-M+sx+AN+9mVWuwzEdrSD1YRimr2csDyXbIBz31wkSyc=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r node_modules $out/lib/node_modules
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js $out/bin/pi
      runHook postInstall
    '';
  };

  # Auto-discover extensions (.ts files)
  # Extensions to keep source but not install
  disabledExtensions = [
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
    packages = [
      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:${pkgs."poppler-utils"}/bin:$PATH"

        # Load Gemini API key for pi-web-access
        if command -v ${pkgs.pass}/bin/pass &>/dev/null; then
          export GEMINI_API_KEY="$(${pkgs.pass}/bin/pass show api/gemini-pi-coding-agent-web-search 2>/dev/null || true)"
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
    }
    // extensionSymlinks
    // skillSymlinks;

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

  programs = {
    fish.shellAliases = {
      pic = "pi -c";
      pir = "pi -r";
    };

    # Catppuccin theme (follows global catppuccin.flavor)
    pi.catppuccin.enable = true;
  };
}
