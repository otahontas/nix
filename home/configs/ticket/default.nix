{ pkgs, ... }:
let
  ticket = pkgs.stdenvNoCC.mkDerivation {
    pname = "ticket";
    version = "unstable-2025-06-15";
    src = pkgs.fetchFromGitHub {
      owner = "wedow";
      repo = "ticket";
      rev = "f4403d9fb1610493b4a003b62bb6063716c2d96d";
      sha256 = "18r1pvzw6f9nygk64v2x4y1c16fpsrqfdsa5mfjj15m19anynl6y";
    };
    dontBuild = true;
    installPhase = ''
      install -Dm755 ticket $out/bin/tk
    '';
  };
in
{
  home.packages = [ ticket ];
}
