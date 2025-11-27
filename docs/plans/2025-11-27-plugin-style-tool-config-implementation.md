# Plugin-Style Tool Configuration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure nix-darwin config so each tool "plugs itself" into the system with all configuration in one place.

**Architecture:** Create tool directories under configs/ containing tool.nix and tool.nu files. Nushell auto-discovers and loads .nu files via directory scanning. Tools remain independent modules imported via home.nix.

**Tech Stack:** Nix, Nushell, home-manager

---

## Task 1: Create git tool directory structure

**Files:**
- Create: `configs/git/git.nix`
- Create: `configs/git/git.nu`
- Modify: `configs/git.nix` (will be deleted after move)

**Step 1: Create git directory**

Run: `mkdir -p configs/git`
Expected: Directory created

**Step 2: Move existing git.nix to git directory**

Run: `mv configs/git.nix configs/git/git.nix`
Expected: File moved

**Step 3: Check if lefthook.yml and commitlint.config.mjs exist**

Run: `ls configs/git/`
Expected: See git.nix, possibly other git-related files

**Step 4: Create empty git.nu file**

Run: `touch configs/git/git.nu`
Expected: File created

**Step 5: Commit**

```bash
git add configs/git/
git commit -m "refactor(git): create git tool directory structure"
```

---

## Task 2: Extract git shell integrations to git.nu

**Files:**
- Modify: `configs/git/git.nu`
- Read: `configs/nushell/config.nu:336-499` (git worktree functions)

**Step 1: Extract git worktree functions from config.nu**

Copy lines 336-499 from `configs/nushell/config.nu` to `configs/git/git.nu`:

```nushell
# Git worktree integration with git-crypt support
def --env git-worktree-new [branch_name: string] {
  $env.HUSKY = "0"

  let repo_root = try {
    ^git rev-parse --show-toplevel | str trim
  } catch {
    error make {msg: "Not in a git repository"}
  }

  let worktree_path = $"($repo_root)/.worktrees/($branch_name)"
  mkdir ($repo_root | path join ".worktrees")

  print $"Creating worktree for branch: ($branch_name)"
  print $"Location: ($worktree_path)"

  # Check for git-crypt
  let has_git_crypt = ($repo_root | path join ".git/git-crypt" | path exists)

  if $has_git_crypt {
    print "Detected git-crypt encryption"
    ^git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add $worktree_path -b $branch_name

    let worktree_basename = ($worktree_path | path basename)
    let git_crypt_target = ($repo_root | path join ".git/git-crypt")
    let git_crypt_link = ($repo_root | path join $".git/worktrees/($worktree_basename)/git-crypt")

    if ($git_crypt_target | path exists) and not ($git_crypt_link | path exists) {
      ^ln -s $git_crypt_target $git_crypt_link
    }

    cd $worktree_path
    try { ^git checkout -- . } catch { }
  } else {
    ^git worktree add $worktree_path -b $branch_name
    cd $worktree_path
  }

  let status = (^git status --short | str trim)
  if ($status | is-not-empty) {
    print "Warning: Worktree has uncommitted changes:"
    print $status
  }

  print ""
  print "✓ Worktree created successfully"
}

def --env git-worktree-pr [pr_number: int] {
  $env.HUSKY = "0"

  let repo_root = try {
    ^git rev-parse --show-toplevel | str trim
  } catch {
    error make {msg: "Not in a git repository"}
  }

  let pr_branch = try {
    ^gh pr view $pr_number --json headRefName -q .headRefName | str trim
  } catch {
    error make {msg: $"Failed to get PR #($pr_number) info"}
  }

  let worktree_dir_name = $"pr-($pr_number)-($pr_branch)"
  let worktree_path = $"($repo_root)/.worktrees/($worktree_dir_name)"
  mkdir ($repo_root | path join ".worktrees")

  print $"Fetching PR #($pr_number)..."
  ^git fetch origin $"pull/($pr_number)/head:($pr_branch)" | lines | where {|line| not ($line | str starts-with "From")}

  print $"Creating worktree for PR #($pr_number)..."

  let has_git_crypt = ($repo_root | path join ".git/git-crypt" | path exists)

  if $has_git_crypt {
    print "Detected git-crypt encryption"
    ^git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add $worktree_path $pr_branch

    let worktree_basename = ($worktree_path | path basename)
    let git_crypt_target = ($repo_root | path join ".git/git-crypt")
    let git_crypt_link = ($repo_root | path join $".git/worktrees/($worktree_basename)/git-crypt")

    if ($git_crypt_target | path exists) and not ($git_crypt_link | path exists) {
      ^ln -s $git_crypt_target $git_crypt_link
    }

    cd $worktree_path
    try { ^git checkout -- . } catch { }
  } else {
    ^git worktree add $worktree_path $pr_branch
    cd $worktree_path
  }

  let status = (^git status --short | str trim)
  if ($status | is-not-empty) {
    print "Warning: Worktree has uncommitted changes:"
    print $status
  }

  print ""
  print $"✓ PR #($pr_number) checked out successfully"
  print $"Location: ($worktree_path)"
}

def git-worktree-prune [branch_name: string] {
  $env.HUSKY = "0"

  let repo_root = try {
    ^git rev-parse --show-toplevel | str trim
  } catch {
    error make {msg: "Not in a git repository"}
  }

  let worktree_path = $"($repo_root)/.worktrees/($branch_name)"

  if not ($worktree_path | path exists) {
    print $"Error: Could not find worktree for branch '($branch_name)'"
    print ""
    print "Available worktrees:"
    ^git worktree list
    return
  }

  print $"Removing worktree: ($worktree_path)"
  ^git worktree remove $worktree_path --force
  print "✓ Worktree removed"

  let branch_exists = (^git show-ref --verify --quiet $"refs/heads/($branch_name)" | complete | get exit_code) == 0
  if $branch_exists {
    print $"Deleting branch: ($branch_name)"
    ^git branch -D $branch_name
    print "✓ Branch deleted"
  }
}

def --env git-worktree-cd [branch_name: string] {
  let repo_root = try {
    ^git rev-parse --show-toplevel | str trim
  } catch {
    error make {msg: "Not in a git repository"}
  }

  let worktree_path = $"($repo_root)/.worktrees/($branch_name)"

  if not ($worktree_path | path exists) {
    print $"Error: Could not find worktree for branch '($branch_name)'"
    print ""
    print "Available worktrees:"
    ^git worktree list
    return
  }

  cd $worktree_path
}

alias gwnew = git-worktree-new
alias gwpr = git-worktree-pr
alias gwcd = git-worktree-cd
alias gwprune = git-worktree-prune
```

**Step 2: Add git aliases to git.nu**

Add at the top of `configs/git/git.nu`:

```nushell
alias gsw = git sw
```

**Step 3: Add lefthook-setup function to git.nu**

Add from lines 115-140 of config.nu:

```nushell
def lefthook-setup [] {
  let repo_root = (git rev-parse --show-toplevel | str trim)
  let template = $"($env.HOME)/.config/git/lefthook.yml"

  if not ($template | path exists) {
    print $"Error: Template not found: ($template)"
    return
  }

  let lefthook_file = $"($repo_root)/lefthook.yml"

  if ($lefthook_file | path exists) {
    let response = (input "lefthook.yml already exists. Overwrite? [y/N] ")
    if ($response | str downcase) not-in ["y", "yes"] {
      print "Cancelled"
      return
    }
  }

  cp $template $lefthook_file
  chmod a+x $lefthook_file
  print $"📝 Created lefthook.yml"

  lefthook install
  print $"✅ Lefthook installed in ($repo_root)"
}
```

**Step 4: Commit**

```bash
git add configs/git/git.nu
git commit -m "refactor(git): extract git functions and aliases to git.nu"
```

---

## Task 3: Extract GitHub CLI helpers to gh.nu

**Files:**
- Create: `configs/gh/gh.nu`
- Modify: `configs/gh.nix` → `configs/gh/gh.nix`
- Read: `configs/nushell/config.nu:502-622` (GitHub functions)

**Step 1: Create gh directory and move gh.nix**

Run: `mkdir -p configs/gh && mv configs/gh.nix configs/gh/gh.nix`
Expected: Directory and file created

**Step 2: Create gh.nu with GitHub CLI helpers**

Extract lines 502-622 from config.nu to `configs/gh/gh.nu`:

```nushell
def gh-pr-get-url [] {
  if (which gh | is-empty) {
    error make {msg: "gh CLI not found"}
  }

  let in_repo = (^git rev-parse --is-inside-work-tree | complete | get exit_code) == 0
  if not $in_repo {
    error make {msg: "Not inside a git repository"}
  }

  let pr_url = try {
    ^gh pr view --json url --jq .url | str trim
  } catch {
    error make {msg: "No pull request found for the current branch"}
  }

  $pr_url
}

def gh-pr-copy-url [] {
  if (which pbcopy | is-empty) {
    error make {msg: "Clipboard tool pbcopy not available"}
  }

  let pr_url = gh-pr-get-url
  $pr_url | pbcopy
  print $"Copied PR URL to clipboard: ($pr_url)"
}

def gh-repo-get-url [] {
  if (which gh | is-empty) {
    error make {msg: "gh CLI not found"}
  }

  let in_repo = (^git rev-parse --is-inside-work-tree | complete | get exit_code) == 0
  if not $in_repo {
    error make {msg: "Not inside a git repository"}
  }

  let repo_url = try {
    ^gh repo view --json url --jq .url | str trim
  } catch {
    error make {msg: "Could not get repository URL"}
  }

  $repo_url
}

def gh-repo-copy-url [] {
  if (which pbcopy | is-empty) {
    error make {msg: "Clipboard tool pbcopy not available"}
  }

  let repo_url = gh-repo-get-url
  $repo_url | pbcopy
  print $"Copied repo URL to clipboard: ($repo_url)"
}

def gh-pr-review [] {
  if (which gh | is-empty) or (which sk | is-empty) {
    error make {msg: "gh and sk are required"}
  }

  let prs = ^gh pr list --state open --limit 100 --json number,title,headRefName,createdAt | from json

  if ($prs | is-empty) {
    print "No open pull requests found"
    return
  }

  let formatted = $prs | each {|pr|
    let created = ($pr.createdAt | into datetime | format date "%Y-%m-%d %H:%M")
    $"($pr.number) | ($pr.title) | ($pr.headRefName) | ($created)"
  }

  let selection = $formatted | str join "\n" | sk --prompt "review> " --header "id | title | branch | created at"

  if ($selection | is-empty) {
    return
  }

  let pr_number = $selection | split row " | " | first | str trim | into int
  ^gh pr view --comments $pr_number
}

def gh-pr-approve-and-merge [] {
  if (which gh | is-empty) or (which sk | is-empty) {
    error make {msg: "gh and sk are required"}
  }

  let prs = ^gh pr list --state open --limit 100 --json number,title,headRefName,createdAt | from json

  if ($prs | is-empty) {
    print "No open pull requests found"
    return
  }

  let formatted = $prs | each {|pr|
    let created = ($pr.createdAt | into datetime | format date "%Y-%m-%d %H:%M")
    $"($pr.number) | ($pr.title) | ($pr.headRefName) | ($created)"
  }

  let selection = $formatted | str join "\n" | sk --prompt "approve+merge> " --header "id | title | branch | created at"

  if ($selection | is-empty) {
    return
  }

  let pr_number = $selection | split row " | " | first | str trim | into int
  print $"Approving PR #($pr_number)..."
  ^gh pr review $pr_number --approve
  print $"Merging PR #($pr_number)..."
  ^gh pr merge $pr_number --auto
}

def gh-run-view [] {
  if (which gh | is-empty) or (which sk | is-empty) {
    error make {msg: "gh and sk are required"}
  }

  let runs = ^gh run list --limit 50 --json status,displayTitle,workflowName,headBranch,databaseId,startedAt,updatedAt,createdAt,conclusion | from json

  if ($runs | is-empty) {
    print "No workflow runs found"
    return
  }

  let formatted = $runs | each {|run|
    let elapsed = if ($run.startedAt | is-empty) {
      "-"
    } else {
      let start = ($run.startedAt | into datetime)
      let end = if ($run.conclusion | is-empty) {
        date now
      } else {
        $run.updatedAt | into datetime
      }
      let diff_secs = (($end - $start) / 1sec | into int)

      if $diff_secs >= 86400 {
        $"($diff_secs / 86400)d($diff_secs mod 86400 / 3600)h"
      } else if $diff_secs >= 3600 {
        $"($diff_secs / 3600)h($diff_secs mod 3600 / 60)m"
      } else if $diff_secs >= 60 {
        $"($diff_secs / 60)m($diff_secs mod 60)s"
      } else {
        $"($diff_secs)s"
      }
    }

    let age = if ($run.createdAt | is-empty) {
      "-"
    } else {
      let created = ($run.createdAt | into datetime)
      let now = date now
      let diff_secs = (($now - $created) / 1sec | into int)

      if $diff_secs >= 86400 {
        $"($diff_secs / 86400)d($diff_secs mod 86400 / 3600)h"
      } else if $diff_secs >= 3600 {
        $"($diff_secs / 3600)h($diff_secs mod 3600 / 60)m"
      } else if $diff_secs >= 60 {
        $"($diff_secs / 60)m($diff_secs mod 60)s"
      } else {
        $"($diff_secs)s"
      }
    }

    let workflow = if ($run.workflowName | is-empty) { "-" } else { $run.workflowName }
    let branch = if ($run.headBranch | is-empty) { "-" } else { $run.headBranch }

    $"($run.status) | ($run.displayTitle) | ($workflow) | ($branch) | ($run.databaseId) | ($elapsed) | ($age)"
  }

  let selection = $formatted | str join "\n" | sk --prompt "runs> " --header "status | title | workflow | branch | id | elapsed | age"

  if ($selection | is-empty) {
    return
  }

  let run_id = $selection | split row " | " | get 4 | str trim | into int
  ^gh run view $run_id
}

def gh-release-slack [pr_number: int] {
  let pr_data = (^gh pr view $pr_number --json title,body --template '{{ .title }}{{"\n"}}{{ .body }}' | complete)

  if $pr_data.exit_code != 0 or ($pr_data.stdout | is-empty) {
    error make {msg: $"Failed to read PR ($pr_number)."}
  }

  let lines = ($pr_data.stdout | lines)
  let title = ($lines | first)
  let release_notes = ($lines | skip 1 | str join "\n")

  let regex_match = ($title | parse -r '^Release\s+(.+?)\s+(\S+)$')

  if ($regex_match | is-empty) {
    error make {msg: $"PR ($pr_number) title \"($title)\" does not match \"Release <service> <version>\" format."}
  }

  let service = ($regex_match | get capture0.0 | str trim)
  let version = ($regex_match | get capture1.0)

  if ($release_notes | str trim | is-empty) {
    error make {msg: $"PR ($pr_number) release notes are empty."}
  }

  let output = $"Release ($service) `($version)`\n\n($release_notes)"

  print $output

  if (which pbcopy | is-not-empty) {
    try {
      $output | pbcopy
      print -e "Copied to clipboard."
    } catch {
      print -e "Failed to copy to clipboard."
    }
  } else {
    print -e "pbcopy not available; clipboard copy skipped."
  }
}
```

**Step 3: Commit**

```bash
git add configs/gh/
git commit -m "refactor(gh): extract GitHub CLI helpers to gh.nu"
```

---

## Task 4: Create other tool directories with shell integrations

**Files:**
- Create: `configs/bat/bat.nu`
- Create: `configs/eza/eza.nu`
- Create: `configs/awscli/awscli.nu`
- Create: `configs/qpdf/qpdf.nu`

**Step 1: Create bat directory and move bat.nix**

Run: `mkdir -p configs/bat && mv configs/bat.nix configs/bat/bat.nix`
Expected: Directory and file created

**Step 2: Create bat.nu with cat alias**

Create `configs/bat/bat.nu`:

```nushell
alias cat = bat
```

**Step 3: Create eza directory for ls aliases**

Run: `mkdir -p configs/eza`
Expected: Directory created

**Step 4: Create eza.nu with ls aliases**

Create `configs/eza/eza.nu`:

```nushell
alias la = ls -a
alias ll = ls -l
alias lla = ls -la
alias ... = cd ../..
alias .... = cd ../../..
```

**Step 5: Create eza.nix**

Create `configs/eza/eza.nix`:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    eza
  ];
}
```

**Step 6: Create awscli directory and move awscli.nix**

Run: `mkdir -p configs/awscli && mv configs/awscli.nix configs/awscli/awscli.nix`
Expected: Directory and file created

**Step 7: Extract acp function to awscli.nu**

Extract lines 697-844 from config.nu to `configs/awscli/awscli.nu`

**Step 8: Create qpdf directory and move qpdf.nix**

Run: `mkdir -p configs/qpdf && mv configs/qpdf.nix configs/qpdf/qpdf.nix`
Expected: Directory and file created

**Step 9: Extract combine-pdfs-in-folder to qpdf.nu**

Extract lines 218-245 from config.nu to `configs/qpdf/qpdf.nu`

**Step 10: Commit**

```bash
git add configs/bat/ configs/eza/ configs/awscli/ configs/qpdf/
git commit -m "refactor: create tool directories for bat, eza, awscli, qpdf"
```

---

## Task 5: Restructure nushell configuration

**Files:**
- Modify: `configs/nushell/config.nu` → `configs/nushell/nushell.nu`
- Modify: `configs/nushell.nix` → `configs/nushell/nushell.nix`

**Step 1: Create nushell directory**

Run: `mkdir -p configs/nushell`
Expected: Directory already exists (contains config.nu)

**Step 2: Move nushell.nix to nushell directory**

Run: `mv configs/nushell.nix configs/nushell/nushell.nix`
Expected: File moved

**Step 3: Remove tool-specific content from config.nu**

Remove these lines from `configs/nushell/config.nu`:
- Line 34: `alias cat = bat` (moved to bat.nu)
- Line 36: `alias gsw = git sw` (moved to git.nu)
- Lines 29-33: ls aliases (moved to eza.nu)
- Lines 115-140: lefthook-setup (moved to git.nu)
- Lines 142-180: gh-release-slack (moved to gh.nu)
- Lines 218-245: combine-pdfs-in-folder (moved to qpdf.nu)
- Lines 333-500: git worktree functions (moved to git.nu)
- Lines 502-692: GitHub CLI functions (moved to gh.nu)
- Lines 697-844: acp AWS function (moved to awscli.nu)

Keep only:
- Lines 1-28: Shell configuration
- Lines 38-114: Generic helpers (week, today, mcd, cl, listening, myip, find-and-prune, daily, disable-sleep, enable-sleep)
- Lines 182-216: mac-open function
- Lines 248-294: Prompt and keybindings
- Lines 850-878: System utilities (cleanup-cache, cleanup-ds-store, trash-empty)

**Step 4: Rename config.nu to nushell.nu**

Run: `mv configs/nushell/config.nu configs/nushell/nushell.nu`
Expected: File renamed

**Step 5: Commit**

```bash
git add configs/nushell/
git commit -m "refactor(nushell): clean up config, keep only generic helpers"
```

---

## Task 6: Implement auto-discovery in nushell.nix

**Files:**
- Modify: `configs/nushell/nushell.nix`

**Step 1: Read current nushell.nix**

Run: `cat configs/nushell.nix` (if still exists) or `cat configs/nushell/nushell.nix`
Expected: See current nushell configuration

**Step 2: Add auto-discovery logic**

Replace `programs.nushell.extraConfig` section with:

```nix
{ pkgs, config, lib, ... }:
let
  # Auto-discover tool integrations
  configsDir = ../..;

  # Get all subdirectories in configs/
  toolDirs = builtins.readDir configsDir;

  # For each tool dir, check if tool.nu exists and read it
  collectNuFiles = lib.attrsets.mapAttrsToList (name: type:
    let
      nuFile = configsDir + "/${name}/${name}.nu";
    in
      if type == "directory" && builtins.pathExists nuFile
      then builtins.readFile nuFile
      else ""
  ) toolDirs;

  # Combine all tool integrations
  allIntegrations = lib.concatStrings collectNuFiles;

  # Read core nushell config
  coreConfig = builtins.readFile ./nushell.nu;
in
{
  home.packages = with pkgs; [
    carapace
    (llm.withPlugins { llm-cmd = true; })
  ];

  catppuccin.nushell.enable = true;

  programs.nushell = {
    enable = true;

    extraEnv = ''
      $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.local/bin")
      $env.VISUAL = "nvim"
      $env.EDITOR = "nvim"
      $env.DOCKER_HOST = "unix:///Users/otahontas/.colima/default/docker.sock"
      $env.MISE_DATA_DIR = $"($env.HOME)/.local/share/mise"
    '';

    # Load core config + auto-discovered tool integrations
    extraConfig = coreConfig + "\n" + allIntegrations;
  };
}
```

**Step 3: Commit**

```bash
git add configs/nushell/nushell.nix
git commit -m "feat(nushell): implement auto-discovery for tool integrations"
```

---

## Task 7: Update home.nix imports

**Files:**
- Modify: `home.nix`

**Step 1: Update import paths**

Replace these lines in `home.nix`:

```nix
    ./configs/bat.nix
    ./configs/gh.nix
    ./configs/git.nix
    ./configs/nushell.nix
    ./configs/awscli.nix
    ./configs/qpdf.nix
```

With:

```nix
    ./configs/bat/bat.nix
    ./configs/eza/eza.nix
    ./configs/gh/gh.nix
    ./configs/git/git.nix
    ./configs/nushell/nushell.nix
    ./configs/awscli/awscli.nix
    ./configs/qpdf/qpdf.nix
```

**Step 2: Commit**

```bash
git add home.nix
git commit -m "refactor: update imports for new tool directory structure"
```

---

## Task 8: Test the new configuration

**Files:**
- None (verification only)

**Step 1: Stage all changes for flake**

Run: `git add .`
Expected: All changes staged

**Step 2: Run format**

Run: `mise run format`
Expected: Files formatted successfully

**Step 3: Stage formatting changes**

Run: `git add .`
Expected: Formatting changes staged

**Step 4: Build and apply configuration**

Run: `mise run build`
Expected: Build succeeds, configuration activates

**Step 5: Verify git aliases work**

Run: `gsw --help` or `git sw --help`
Expected: Git switch help displayed

**Step 6: Verify git worktree functions available**

Run: `which git-worktree-new`
Expected: Function found

**Step 7: Verify bat alias works**

Run: `cat ~/.config/nix-darwin/README.md | head -5`
Expected: Bat-formatted output

**Step 8: Verify ls aliases work**

Run: `ll`
Expected: Long listing format

**Step 9: Commit test verification**

```bash
git commit -m "test: verify new plugin-style configuration works"
```

---

## Task 9: Clean up old structure

**Files:**
- Delete: Any remaining orphaned .nix files in configs/

**Step 1: Check for orphaned files**

Run: `fd -t f "\.nix$" configs/ -x echo`
Expected: List of .nix files

**Step 2: Verify no orphaned files remain**

All .nix files should be in tool subdirectories. If any remain in configs/ root, move or delete them.

**Step 3: Final commit**

```bash
git add .
git commit -m "chore: cleanup complete - plugin-style config implemented"
```
