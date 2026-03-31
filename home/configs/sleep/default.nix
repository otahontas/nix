{ pkgs, ... }:
let
  disableSleep = pkgs.writeShellScriptBin "disable-sleep" ''
    sudo pmset -a disablesleep 1
  '';
  enableSleep = pkgs.writeShellScriptBin "enable-sleep" ''
    sudo pmset -a disablesleep 0
  '';
in
{
  home.packages = [
    disableSleep
    enableSleep
  ];
}
