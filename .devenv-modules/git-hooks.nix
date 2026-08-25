{ inputs, pkgs, ... }:

let
  configFileValidator =
    inputs.otahontas-nixpkgs.packages.${pkgs.stdenv.hostPlatform.system}.config-file-validator;
  piNodeModules = "${
    inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent
  }/lib/node_modules";
  preparePiExtensionNodeModules = ''
    ${pkgs.coreutils}/bin/mkdir -p .devenv
    if [ -e .devenv/pi-node-modules ] && [ ! -L .devenv/pi-node-modules ]; then
      echo ".devenv/pi-node-modules exists but is not a symlink" >&2
      exit 1
    fi
    ${pkgs.coreutils}/bin/ln -sfn "${piNodeModules}" .devenv/pi-node-modules
  '';
in
{
  enterShell = preparePiExtensionNodeModules;

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
    # @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Config schema diagnostics]]
    config-schema = {
      enable = true;
      entry = "${configFileValidator}/bin/validator";
      args = [
        "-quiet"
        "-no-config"
        "-schemastore"
        "-schema-map=devenv.yaml:https://devenv.sh/devenv.schema.json"
        "-schema-map=**/devenv.yaml:https://devenv.sh/devenv.schema.json"
        "-file-types=json,yaml,toml"
      ];
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
    typescript-typecheck = {
      enable = true;
      entry = "${pkgs.writeShellScript "typescript-typecheck" ''
        set -euo pipefail
        ${preparePiExtensionNodeModules}
        exec ${pkgs.typescript}/bin/tsc -p tsconfig.json --noEmit --pretty false
      ''}";
      files = "\\.ts$";
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
