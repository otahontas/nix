{ pkgs, ... }:
let
  sleepScript = builtins.readFile ./scripts/sleep.sh;
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "disable-sleep" sleepScript)
    (pkgs.writeShellScriptBin "enable-sleep" sleepScript)
  ];
}
