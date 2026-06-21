{ pkgs }:

let
  version = "0.19.27";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "plannotator";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${version}/plannotator-darwin-arm64";
    hash = "sha256-3KawFZVwa3jeD3rj2WGZiIlIdW9Ue83x2/yYOfm9toQ=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/plannotator"
  '';
}
