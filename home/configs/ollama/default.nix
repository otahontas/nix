{ pkgs, ... }:
let
  ollama-bin = pkgs.stdenv.mkDerivation rec {
    pname = "ollama-bin";
    version = "0.20.2";
    src = pkgs.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-darwin.tgz";
      hash = "sha256-/i0LLqNgpXZfmrdRzY1hVQE5Ov9TReIYkMwDMPQ66kQ=";
    };
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out/bin
      cp ollama $out/bin/
      chmod +x $out/bin/ollama
    '';
  };
in
{
  home.packages = [ ollama-bin ];
}
