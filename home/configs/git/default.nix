{ config, pkgs, ... }:
{
  home = {
    packages = [
      pkgs.lefthook
    ];
    file.".ssh/allowed_signers".source = ./allowed_signers;
  };
  xdg.configFile = {
    "git/lefthook.yml".source = ./lefthook.yml;
    "commitlint/commitlint.config.mjs".source = ./commitlint.config.mjs;
  };
  programs = {
    gh = {
      enable = true;
      settings = {
        editor = "nvim";
        git_protocol = "ssh";
        pager = "bat";
        prompt = "enabled";
        aliases = {
          co = "pr checkout";
          web = "repo view --web";
        };
      };
    };
    git = {
      enable = true;
      signing = {
        key = "26E61F9D378C7358";
        signByDefault = true;
      };
      settings = {
        user = {
          name = "Otto Ahoniemi";
          email = "otto@ottoahoniemi.fi";
        };
        push = {
          default = "matching";
          followTags = true;
        };
        pull = {
          rebase = true;
        };
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
        difftool = {
          nvim_difftool.cmd = ''nvim -c "packadd nvim.difftool" -c "DiffTool $LOCAL $REMOTE"'';
        };
        tag.gpgsign = true;
        commit.gpgsign = true;
        gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
        init.defaultBranch = "main";
        rebase = {
          updateRefs = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
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
          logs = "log --show-signature";
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
        "**/.worktrees/**"
        "**/.local_scripts/**"
      ];
    };
    fish = {
      interactiveShellInit =
        builtins.readFile ./lefthook.fish + builtins.readFile ./worktree.fish + builtins.readFile ./gh.fish;
      shellAliases = {
        gsw = "git sw";
        gwcd = "git-worktree-cd";
        gwnew = "git-worktree-new";
        gwpr = "git-worktree-pr";
        gwprune = "git-worktree-prune";
      };
    };
  };
}
