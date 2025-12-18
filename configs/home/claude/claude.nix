{ pkgs, ... }:
let
  claudeWithNode = pkgs.writeShellScriptBin "claude" ''
    export PATH="${pkgs.nodejs_24}/bin:$PATH"
    exec ${pkgs.claude-code}/bin/claude "$@"
  '';
in
{
  home.packages = [ claudeWithNode ];
}
