_:
let
  bashFiles = [
    ./worktree-functions.bash
    ./worktree-completions.bash
  ];
in
{
  programs.bash = {
    enable = true;
    bashrcExtra = builtins.concatStringsSep "\n" (map builtins.readFile bashFiles);
  };
}
