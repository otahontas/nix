{ pkgs, ... }:
let
  yk-status = pkgs.writeShellScriptBin "yk-status" (builtins.readFile ./scripts/yk-status.sh);
in
{
  home = {
    packages = [
      pkgs.yubikey-manager
      yk-status
    ];
  };
}
