let
  sharedAliases = {
    cat = "bat";
    gsw = "git sw";
    gwcd = "git-worktree-cd";
    gwnew = "git-worktree-new";
    gwpr = "git-worktree-pr";
    gwprune = "git-worktree-prune";
    pic = "pi -c";
    pir = "pi -r";
  };
in
{
  programs = {
    bash.shellAliases = sharedAliases;
    fish.shellAliases = sharedAliases;
  };
}
