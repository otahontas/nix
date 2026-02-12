{ pkgs, ... }:
let
  ticket = pkgs.stdenvNoCC.mkDerivation {
    pname = "ticket";
    version = "unstable-2025-06-15";
    src = pkgs.fetchFromGitHub {
      owner = "otahontas";
      repo = "ticket";
      rev = "ce72583fa0a68fe6221c710ba7ce806dc2468609";
      sha256 = "1kvpczmway07wzbb08v8ws178xcarqsjxssmrirkab6xnandzajm";
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
