{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
  ];

  programs.nushell.shellAliases = {
    c = "claude";
    cc = "claude -c";
    cr = "claude -r";
    colo = "claude --dangerously-skip-permissions";
    ccolo = "claude -c --dangerously-skip-permissions";
    crolo = "claude -r --dangerously-skip-permissions";
  };
}
