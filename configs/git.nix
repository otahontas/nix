{ config, ... }:
{
  programs.git = {
    enable = true;

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNqZN/gQy2WDb5T4f9dLpmNQ1YhJDfq3eB12lZDvX8J";
      signByDefault = true;
    };

    settings = {
      user = {
        name = "Otto Ahoniemi";
        email = "otto@ottoahoniemi.fi";
      };

      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };

      push = {
        default = "matching";
        followTags = true;
      };

      pull.rebase = true;

      merge = {
        tool = "nvim_mergetool";
        conflictstyle = "zdiff3";
      };

      mergetool = {
        keepBackup = false;
        nvim_mergetool.cmd = "nvim -d $LOCAL $REMOTE $MERGED -c '$wincmd w' -c 'wincmd J'";
      };

      diff = {
        tool = "nvim_difftool";
        colorMoved = "default";
      };

      difftool.nvim_difftool.cmd = ''nvim -c "packadd nvim.difftool" -c "DiffTool $LOCAL $REMOTE"'';

      tag.gpgsign = true;

      commit.gpgsign = true;

      init = {
        defaultBranch = "main";
        templatedir = "/Users/otahontas/.config/git/template";
      };

      interactive.diffFilter = "delta --color-only";

      core.pager = "delta";

      delta = {
        navigate = true;
        side-by-side = true;
        hyperlinks = true;
        dark = false;
      };

      alias = {
        a = "add";
        ap = "add -p";
        br = "branch";
        c = "commit";
        cane = "commit --amend --no-edit";
        cedit = "commit --amend";
        cm = "commit -m";
        co = "checkout";
        cp = "cherry-pick";
        d = "diff";
        dad = "!curl https://icanhazdadjoke.com/";
        ddb = "diff-default-branch";
        default-branch-name = "!git symbolic-ref refs/remotes/\${remote:-origin}/HEAD | awk -F/ '{print $NF}'";
        diff-default-branch = "!git diff $(git default-branch-name)";
        difftool-default-branch = "!git difftool -d $(git default-branch-name)";
        ds = "diff --staged";
        dt = "difftool";
        dtd = "difftool -d";
        dtdb = "difftool-default-branch";
        f = "fetch";
        fa = "fetch --all";
        hidden = "!git ls-files -v . | grep '^S'";
        hide = "update-index --skip-worktree";
        hist = "log --pretty=format:'%h %aD | %s%d [%an]' --graph --date=short";
        ignore = "!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi";
        last = "log -1 HEAD";
        mt = "mergetool";
        poh = "push origin HEAD";
        pohf = "push --force origin HEAD";
        ra = "rebase --abort";
        rc = "rebase --continue";
        re = "restore";
        res = "restore --staged";
        ri = "rebase -i";
        root = "rev-parse --show-toplevel";
        rp = "restore -p";
        rsp = "restore --staged -p";
        s = "status";
        sd = "stash drop stash@{0}";
        sl = "stash list";
        ss = "stash show -p";
        sw = "switch";
        undo = "reset --soft HEAD^";
        unhide = "update-index --no-skip-worktree";
        wt = "worktree";
      };
    };

    ignores = [
      ".DS_Store"
      ".localized"
      "**/.claude/**.json"
      "**/.local_scripts/**"
      "**/.worktrees/**"
    ];
  };

  xdg.configFile."git/template" = {
    source = ./git/template;
    recursive = true;
  };

  xdg.configFile."git/hooks-lib" = {
    source = ./git/hooks-lib;
    recursive = true;
  };
}
