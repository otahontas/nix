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
  configFileValidator =
    inputs.otahontas-nixpkgs.packages.${pkgs.stdenv.hostPlatform.system}.config-file-validator;
in
{
  _module.args = {
    inherit configFileValidator piExtensionsTypecheck;
  };

  enterShell = preparePiExtensionNodeModules;
}
