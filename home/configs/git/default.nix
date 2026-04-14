{ pkgs, config, ... }:
let

  format-duration = pkgs.writeShellScriptBin "format-duration" (
    builtins.readFile ./scripts/format-duration.sh
  );
  gh-pr-select = pkgs.writeShellScriptBin "gh-pr-select" (
    builtins.readFile ./scripts/gh-pr-select.sh
  );
  gh-pr-get-url = pkgs.writeShellScriptBin "gh-pr-get-url" (
    builtins.readFile ./scripts/gh-pr-get-url.sh
  );
  gh-pr-copy-url = pkgs.writeShellScriptBin "gh-pr-copy-url" (
    builtins.readFile ./scripts/gh-pr-copy-url.sh
  );
  gh-repo-get-url = pkgs.writeShellScriptBin "gh-repo-get-url" (
    builtins.readFile ./scripts/gh-repo-get-url.sh
  );
  gh-repo-copy-url = pkgs.writeShellScriptBin "gh-repo-copy-url" (
    builtins.readFile ./scripts/gh-repo-copy-url.sh
  );
  gh-pr-review = pkgs.writeShellScriptBin "gh-pr-review" (
    builtins.readFile ./scripts/gh-pr-review.sh
  );
  gh-pr-approve-and-merge = pkgs.writeShellScriptBin "gh-pr-approve-and-merge" (
    builtins.readFile ./scripts/gh-pr-approve-and-merge.sh
  );
  gh-run-view = pkgs.writeShellScriptBin "gh-run-view" (builtins.readFile ./scripts/gh-run-view.sh);
  gh-release-slack = pkgs.writeShellScriptBin "gh-release-slack" (
    builtins.readFile ./scripts/gh-release-slack.sh
  );
  git-worktree-prune = pkgs.writeShellScriptBin "git-worktree-prune" (
    builtins.readFile ./scripts/git-worktree-prune.sh
  );
in
{
  home = {
    file.".ssh/allowed_signers".source = ./allowed_signers;

    packages = [
      format-duration
      gh-pr-select
      gh-pr-get-url
      gh-pr-copy-url
      gh-repo-get-url
      gh-repo-copy-url
      gh-pr-review
      gh-pr-approve-and-merge
      gh-run-view
      gh-release-slack
      git-worktree-prune
    ];
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
        "**/plans/**"
        "**/.tickets/logs/**"
      ];
    };

    fish = {
      interactiveShellInit = builtins.readFile ./worktree.fish;
    };
  };
}
