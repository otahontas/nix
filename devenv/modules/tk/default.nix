{ pkgs, ... }:
let
  tk = pkgs.stdenvNoCC.mkDerivation {
    pname = "tk";
    version = "v0.3.2";
    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/wedow/ticket/v0.3.2/ticket";
      hash = "sha256-QI8sET7MO8BxUHWTp4OG8bTMdDvmSRyenyYn79TZkCs=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/tk
    '';
  };
in
{
  packages = [
    tk
  ];
}
