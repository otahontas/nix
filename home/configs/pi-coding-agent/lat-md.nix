{
  pkgs,
  lib,
  ...
}:
let
  version = "0.11.0";

  latMd = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "lat-md";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "1st1";
      repo = "lat.md";
      tag = "v${version}";
      hash = "sha256-01gLYPiwzhTwIgGtx81aieCnVYBoy6WJ8zfEGEmL2Hs=";
    };

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.pnpm_10
      pkgs.pnpmConfigHook
      pkgs.makeWrapper
    ];

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      pnpm = pkgs.pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-z9M1T+qMB43Fewb92W5VCfC5LXBW5IDX6yKIDJBrDlY=";
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      pnpm prune --prod
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/node_modules/lat.md" "$out/bin"
      cp -R dist templates package.json node_modules "$out/lib/node_modules/lat.md/"
      makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/lat" \
        --add-flags "$out/lib/node_modules/lat.md/dist/src/cli/index.js"
      runHook postInstall
    '';

    meta = {
      description = "Knowledge graph for codebases, written in markdown";
      homepage = "https://github.com/1st1/lat.md";
      license = lib.licenses.mit;
      mainProgram = "lat";
    };
  });
in
{
  _module.args.piLatMd = latMd;
}
