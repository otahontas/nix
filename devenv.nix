{ inputs, pkgs, ... }:

let
  piPackage = inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;
  piNodeModules = "${piPackage}/lib/node_modules";
  preparePiExtensionNodeModules = ''
    ${pkgs.coreutils}/bin/mkdir -p .devenv
    if [ -e .devenv/pi-node-modules ] && [ ! -L .devenv/pi-node-modules ]; then
      echo ".devenv/pi-node-modules exists but is not a symlink" >&2
      exit 1
    fi
    ${pkgs.coreutils}/bin/ln -sfn "${piNodeModules}" .devenv/pi-node-modules
  '';
  piExtensionsTypecheck = pkgs.writeShellScript "pi-extensions-typecheck" ''
    set -euo pipefail
    ${preparePiExtensionNodeModules}
    exec ${pkgs.typescript}/bin/tsc -p tsconfig.json --noEmit --pretty false
  '';
  # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Config schema diagnostics]]
  config-file-validator = pkgs.buildGoModule rec {
    pname = "config-file-validator";
    version = "2.2.2";

    src = pkgs.fetchFromGitHub {
      owner = "Boeing";
      repo = "config-file-validator";
      rev = "v${version}";
      hash = "sha256-NX/GjicrpM4iCztAPPiiLrDCIImC8gWG5cgmkEPiyAg=";
    };

    vendorHash = "sha256-q8tpLBtmg061BnQnv6DE56+eYPmFNfYV+vBbPQRCwwE=";
    subPackages = [ "cmd/validator" ];
    ldflags = [ "-X github.com/Boeing/config-file-validator/v2.version=v${version}" ];
    nativeCheckInputs = [ pkgs.git ];

    postPatch = ''
      substituteInPlace cmd/validator/testdata/gitignore.txtar \
        --replace-fail "! stdout 'build'" "! stdout 'build.output.json'"
    '';

    meta = {
      description = "Cross-platform CLI tool to validate configuration files";
      homepage = "https://github.com/Boeing/config-file-validator";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "validator";
    };
  };
in
{
  packages =
    (with pkgs; [
      emmylua-check
      emmylua-ls
      fish-lsp
      markdownlint-cli
      stylua
      taplo
      typescript
      typescript-language-server
      vscode-json-languageserver
      yaml-language-server
    ])
    ++ [
      config-file-validator
    ];

  treefmt = {
    enable = true;
    config = {
      settings.global.excludes = [
        "*.lock"
        "*.lockb"
        ".devenv*"
        ".pi/extensions/lat.ts"
        ".pi/skills/lat-md/SKILL.md"
        "AGENTS.md"
        "home/configs/git/allowed_signers"
        "system/keyboard/*.keylayout"
      ];
      programs = {
        fish_indent.enable = true;
        nixfmt.enable = true;
        prettier.enable = true;
        shfmt.enable = true;
        stylua.enable = true;
        taplo.enable = true;
      };
    };
  };

  languages = {
    lua.enable = true;
    nix.enable = true;
    shell.enable = true;
  };

  enterShell = preparePiExtensionNodeModules;

  tasks = {
    "home:apply" = {
      description = "Apply home-manager configuration from ./home flake";
      exec = "home-manager switch --flake ./home";
    };
    "system:apply" = {
      description = "Apply system from ./system flake";
      exec = "sudo darwin-rebuild switch --flake ./system";
    };
    "nix:format" = {
      description = "Run treefmt formatters";
      exec = "treefmt -v";
    };
    "nix:update" = {
      description = "Update flakes, devenv, home-manager, and pi extensions";
      exec = ''
        nix flake update --flake ./home
        nix flake update --flake ./system
        devenv update
        devenv tasks run home:apply && pi update --extensions
      '';
    };
    "pi-extensions:typecheck" = {
      description = "Typecheck local Pi TypeScript extensions";
      exec = "${piExtensionsTypecheck}";
    };
  };

  git-hooks.hooks = {
    check-merge-conflicts.enable = true;
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Nix diagnostics]]
    deadnix.enable = true;
    detect-private-keys.enable = true;
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Bash diagnostics]]
    shellcheck = {
      enable = true;
      entry = "${pkgs.writeShellScript "shellcheck-source-following" ''
        set -euo pipefail
        for file in "$@"; do
          ${pkgs.shellcheck}/bin/shellcheck --external-sources --source-path="$(${pkgs.coreutils}/bin/dirname "$file")" "$file"
        done
      ''}";
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Fish diagnostics]]
    fish-syntax = {
      enable = true;
      entry = "${pkgs.writeShellScript "fish-syntax-check" ''
        set -euo pipefail
        for file in "$@"; do
          ${pkgs.fish}/bin/fish --no-execute "$file"
        done
      ''}";
      files = "\\.fish$";
      types = [ "file" ];
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#JSON diagnostics]]
    json-syntax = {
      enable = true;
      entry = "${pkgs.jq}/bin/jq empty";
      files = "\\.json$";
      types = [ "file" ];
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Config schema diagnostics]]
    config-schema = {
      enable = true;
      entry = "${pkgs.writeShellScript "config-schema-check" ''
        set -euo pipefail
        ${config-file-validator}/bin/validator \
          -quiet \
          -no-config \
          -schemastore \
          -schema-map="devenv.yaml:https://devenv.sh/devenv.schema.json" \
          -schema-map="**/devenv.yaml:https://devenv.sh/devenv.schema.json" \
          -file-types=json,yaml,toml \
          "$@"
      ''}";
      files = "\\.(json|ya?ml|toml)$";
      types = [ "file" ];
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Lua diagnostics]]
    lua-lint = {
      enable = true;
      entry = "${pkgs.emmylua-check}/bin/emmylua_check --config .emmyrc.json --warnings-as-errors";
      files = "\\.lua$";
      types = [ "file" ];
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#TypeScript diagnostics]]
    pi-extensions-typecheck = {
      enable = true;
      entry = "${piExtensionsTypecheck}";
      files = "^(\\.pi/extensions/.*\\.ts|home/configs/pi-coding-agent/extensions/.*\\.ts|tsconfig\\.json|devenv\\.(nix|yaml))$";
      pass_filenames = false;
      types = [ "file" ];
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Markdown diagnostics]]
    markdownlint.enable = true;
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#TOML diagnostics]]
    toml-lint = {
      enable = true;
      entry = "${pkgs.taplo}/bin/taplo lint";
      files = "\\.toml$";
      types = [ "file" ];
    };
    commitlint = {
      enable = true;
      stages = [ "commit-msg" ];
      entry = "${pkgs.commitlint}/bin/commitlint --extends @commitlint/config-conventional --edit";
    };
    gitleaks = {
      enable = true;
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --verbose";
    };
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Nix diagnostics]]
    statix = {
      enable = true;
      entry = "${pkgs.statix}/bin/statix check --format errfmt --ignore .devenv,.devenv.* .";
      pass_filenames = false;
    };
    treefmt.enable = true;
    yamllint = {
      enable = true;
      settings.preset = "relaxed";
    };
  };
}
