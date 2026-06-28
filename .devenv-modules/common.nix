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
  configFileValidator = pkgs.buildGoModule rec {
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
  _module.args = {
    inherit configFileValidator piExtensionsTypecheck;
  };

  enterShell = preparePiExtensionNodeModules;
}
