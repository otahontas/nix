{ pkgs, lib, ... }:
let
  yt-dlp-wrapped = pkgs.writeShellScriptBin "yt-dlp" ''
    export PATH="${pkgs.aria2}/bin:$PATH"
    exec ${lib.getExe pkgs.yt-dlp} "$@"
  '';
in
{
  home.packages = [
    yt-dlp-wrapped
  ];

  xdg.configFile."yt-dlp/config".source = ./config;
}
