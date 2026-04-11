{ pkgs, config, ... }:
let
  format-duration = pkgs.writeShellScriptBin "format-duration" ''
    secs=$1
    if [ "$secs" -ge 86400 ]; then
      days=$((secs / 86400))
      hours=$((secs % 86400 / 3600))
      echo "''${days}d''${hours}h"
    elif [ "$secs" -ge 3600 ]; then
      hours=$((secs / 3600))
      mins=$((secs % 3600 / 60))
      echo "''${hours}h''${mins}m"
    elif [ "$secs" -ge 60 ]; then
      mins=$((secs / 60))
      remainder=$((secs % 60))
      echo "''${mins}m''${remainder}s"
    else
      echo "''${secs}s"
    fi
  '';

  gh-pr-select = pkgs.writeShellScriptBin "gh-pr-select" ''
    prompt="''${1:-}> "
    prs=$(gh pr list --state open --limit 100 --json number,title,headRefName,createdAt)

    if [ -z "$prs" ] || [ "$prs" = "[]" ]; then
      echo "No open pull requests found" >&2
      exit 1
    fi

    formatted=$(echo "$prs" | jq -r '.[] | "\(.number) | \(.title) | \(.headRefName) | \(.createdAt | split(\"T\")[0] + \" \" + .createdAt | split(\"T\")[1] | split(\".\")[0])"')

    selection=$(echo "$formatted" | fzf --prompt "$prompt" --header "id | title | branch | created at")

    if [ -z "$selection" ]; then
      exit 1
    fi

    echo "$selection" | cut -d'|' -f1 | xargs
  '';

  gh-pr-get-url = pkgs.writeShellScriptBin "gh-pr-get-url" ''
    url=$(gh pr view --json url --jq .url 2>/dev/null)
    if [ -z "$url" ]; then
      echo "No pull request found for the current branch" >&2
      exit 1
    fi
    echo "$url"
  '';

  gh-pr-copy-url = pkgs.writeShellScriptBin "gh-pr-copy-url" ''
    pr_url=$(gh-pr-get-url) || exit 1
    echo "$pr_url" | pbcopy
    echo "Copied PR URL to clipboard: $pr_url"
  '';

  gh-repo-get-url = pkgs.writeShellScriptBin "gh-repo-get-url" ''
    url=$(gh repo view --json url --jq .url 2>/dev/null)
    if [ -z "$url" ]; then
      echo "Could not get repository URL" >&2
      exit 1
    fi
    echo "$url"
  '';

  gh-repo-copy-url = pkgs.writeShellScriptBin "gh-repo-copy-url" ''
    repo_url=$(gh-repo-get-url) || exit 1
    echo "$repo_url" | pbcopy
    echo "Copied repo URL to clipboard: $repo_url"
  '';

  gh-pr-review = pkgs.writeShellScriptBin "gh-pr-review" ''
    pr_number=$(gh-pr-select "review> ") || exit 1
    gh pr view --comments "$pr_number"
  '';

  gh-pr-approve-and-merge = pkgs.writeShellScriptBin "gh-pr-approve-and-merge" ''
    pr_number=$(gh-pr-select "approve+merge> ") || exit 1
    echo "Approving PR #$pr_number..."
    gh pr review "$pr_number" --approve
    echo "Merging PR #$pr_number..."
    gh pr merge "$pr_number" --auto
  '';

  gh-run-view = pkgs.writeShellScriptBin "gh-run-view" ''
    runs=$(gh run list --limit 50 --json status,displayTitle,workflowName,headBranch,databaseId,startedAt,updatedAt,createdAt,conclusion)

    if [ -z "$runs" ] || [ "$runs" = "[]" ]; then
      echo "No workflow runs found"
      exit 0
    fi

    formatted=$(echo "$runs" | jq -r '.[] |
      (.status) + " | " +
      (.displayTitle) + " | " +
      (.workflowName // "-") + " | " +
      (.headBranch // "-") + " | " +
      (.databaseId | tostring) + " | " +
      (if .startedAt == null or .startedAt == "" then "-" else .startedAt end) + " | " +
      (if .createdAt == null or .createdAt == "" then "-" else .createdAt end)')

    selection=$(echo "$formatted" | fzf --prompt "runs> " --header "status | title | workflow | branch | id | started | created")

    if [ -z "$selection" ]; then
      exit 0
    fi

    run_id=$(echo "$selection" | cut -d'|' -f5 | xargs)
    gh run view "$run_id"
  '';

  gh-release-slack = pkgs.writeShellScriptBin "gh-release-slack" ''
        pr_number="$1"

        if [ -z "$pr_number" ]; then
          echo "Usage: gh-release-slack <pr_number>" >&2
          exit 1
        fi

        pr_data=$(gh pr view "$pr_number" --json title,body --template '{{ .title }}\n{{ .body }}' 2>/dev/null)

        if [ -z "$pr_data" ]; then
          echo "Failed to read PR $pr_number." >&2
          exit 1
        fi

        title=$(echo "$pr_data" | head -n1)
        release_notes=$(echo "$pr_data" | tail -n +2)

        # Parse title with format "Release <service> <version>"
        if ! echo "$title" | grep -qE '^Release\s+.+?\s+\S+$'; then
          echo "PR $pr_number title \"$title\" does not match \"Release <service> <version>\" format." >&2
          exit 1
        fi

        service=$(echo "$title" | sed -E 's/^Release\s+(.+?)\s+\S+$/\1/')
        version=$(echo "$title" | awk '{print $NF}')

        if [ -z "$(echo "$release_notes" | xargs)" ]; then
          echo "PR $pr_number release notes are empty." >&2
          exit 1
        fi

        output="Released $service \`$version\`

    $release_notes"
        echo "$output"
        echo "$output" | pbcopy
        echo "Copied to clipboard." >&2
  '';

  # gwprune does not cd - convert to script
  git-worktree-prune = pkgs.writeShellScriptBin "git-worktree-prune" ''
    branch_name="$1"

    if [ -z "$branch_name" ]; then
      echo "Usage: git-worktree-prune <branch_name>"
      exit 1
    fi

    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$repo_root" ]; then
      echo "Error: Not in a git repository"
      exit 1
    fi

    worktree_path="$repo_root/.worktrees/$branch_name"

    if [ ! -d "$worktree_path" ]; then
      echo "Error: Could not find worktree for branch '$branch_name'"
      echo ""
      echo "Available worktrees:"
      git worktree list
      exit 1
    fi

    echo "Removing worktree: $worktree_path"
    git worktree remove "$worktree_path" --force
    echo "✓ Worktree removed"

    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
      echo "Deleting branch: $branch_name"
      git branch -D "$branch_name"
      echo "✓ Branch deleted"
    fi
  '';
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
        "*plan*.md"
      ];
    };

    fish = {
      interactiveShellInit = builtins.readFile ./worktree.fish;
    };
  };
}
