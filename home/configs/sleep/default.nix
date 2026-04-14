{ pkgs, ... }:
let
  disableSleep = pkgs.writeShellScriptBin "disable-sleep" (
    builtins.readFile ./scripts/disable-sleep.sh
  );
  enableSleep = pkgs.writeShellScriptBin "enable-sleep" (builtins.readFile ./scripts/enable-sleep.sh);
in
{
  home.packages = [
    disableSleep
    enableSleep
  ];
}
