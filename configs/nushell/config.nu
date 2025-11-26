$env.SHELL = (which nu).path.0
$env.STARSHIP_SHELL = "nu"

source $"($nu.cache-dir)/carapace.nu"

$env.config.show_banner = false

$env.config.completions = {
  case_sensitive: false
  algorithm: "fuzzy"
  quick: true
  partial: true
  use_ls_colors: true
}

$env.config.history = {
  max_size: 10000
  sync_on_enter: true
  file_format: "sqlite"
  isolation: false
}

$env.config.edit_mode = "vi"
$env.config.cursor_shape = {
  vi_insert: line
  vi_normal: block
}

alias ... = cd ../..
alias .... = cd ../../..
alias la = ls -a
alias ll = ls -l
alias lla = ls -la
alias cat = bat
alias todo = nvim ~/Documents/todo/todo.txt
alias gsw = git sw

def week [] { date now | format date "%U" }
def today [] { date now | format date "%F" }

def mcd [dir: string] {
  mkdir $dir
  cd $dir
}

def cl [dir: string] {
  cd $dir
  ls
}

def listening [pattern?: string] {
  let ports = (sudo lsof -iTCP -sTCP:LISTEN -n -P | from ssv)

  if ($pattern | is-empty) {
    $ports
  } else {
    $ports | where { |row|
      ($row | values | any { |val| ($val | into string) =~ $pattern })
    }
  }
}

def myip [] {
  ifconfig
    | lines
    | where ($it | str contains "inet ")
    | where { |line| not ($line | str contains "127.0.0.1") }
    | each { |line| $line | str trim | split row ' ' | get 1 }
}

def find-and-prune [pattern: string] {
  print $"This will delete all files/directories matching: ($pattern)"
  let response = (input "Are you sure? [y/N] ")

  if ($response | str downcase) in ["y", "yes"] {
    fd -H $pattern --exec rm -rf
  } else {
    print "Cancelled"
  }
}

def daily [date?: string] {
  let notes_dir = $"($env.HOME)/Documents/notes/daily"

  let date_str = if ($date | is-empty) {
    date now | format date "%Y-%m-%d"
  } else {
    $date
  }

  let note_path = $"($notes_dir)/($date_str).md"
  mkdir $notes_dir

  if not ($note_path | path exists) {
    touch $note_path
  }

  if ($env.VISUAL? | is-not-empty) {
    ^$env.VISUAL $note_path
  } else if ($env.EDITOR? | is-not-empty) {
    ^$env.EDITOR $note_path
  } else {
    open $note_path
  }
}

def disable-sleep [] {
  sudo pmset -a disablesleep 1
}

def enable-sleep [] {
  sudo pmset -a disablesleep 0
}

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

def mac-open [
  --skip                     # Skip text file detection and use system open
  -a: string                 # Application to use for opening
  ...args: string            # Files or URLs to open
] {
  if ($args | is-empty) {
    error make {msg: "Usage: mac-open [--skip] [-a application] ...arguments"}
  }

  # If "--skip" flag is provided, use system open directly
  if $skip {
    ^/usr/bin/open ...$args
    return
  }

  # If "-a" flag is provided, assume it's an app launch and bypass text handling
  if ($a | is-not-empty) {
    ^/usr/bin/open -a $a ...$args
    return
  }

  # Check if the first argument is a file and get its MIME type
  let file_path = $args.0
  if ($file_path | path exists) and ($file_path | path type) == "file" {
    let input_mime_type = (^file -b --mime-type $file_path | str trim)

    if ($input_mime_type | str starts-with "text/") or ($input_mime_type == "application/json") {
      ^$env.EDITOR ...$args
      return
    }
  }

  # Otherwise, open the file in the default application
  ^/usr/bin/open ...$args
}

# Initialize Starship prompt
def create_left_prompt [] {
  starship prompt --cmd-duration $env.CMD_DURATION_MS --status $env.LAST_EXIT_CODE
}

def create_right_prompt [] {
  ""
}

$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }

# Completion menu configuration (fzf-tab style)
$env.config.keybindings ++= [
  {
    name: completion_menu
    modifier: none
    keycode: tab
    mode: [emacs, vi_normal, vi_insert]
    event: {
      until: [
        { send: menu name: completion_menu }
        { send: menunext }
        { edit: complete }
      ]
    }
  }
  {
    name: completion_previous
    modifier: shift
    keycode: backtab
    mode: [emacs, vi_normal, vi_insert]
    event: { send: menuprevious }
  }
]

# LLM command completion keybinding (Alt-\)
$env.config.keybindings ++= [{
  name: llm_cmdcomp
  modifier: alt
  keycode: char_\
  mode: [emacs, vi_normal, vi_insert]
  event: {
    send: executehostcommand
    cmd: "commandline edit --replace (commandline | llm -s 'You are a shell command generator for macOS using Nushell. Convert the user request into a valid shell command. Return ONLY the command, no explanation, no markdown, no code blocks. Just the raw command that can be executed in Nushell.' | str trim)"
  }
}]

# Skim fuzzy finder keybindings
$env.config.keybindings ++= [
  # CTRL-T: File/directory selection
  {
    name: skim_file_select
    modifier: control
    keycode: char_t
    mode: [emacs, vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "commandline edit --insert (fd --type f --hidden --follow --exclude .git | sk --multi --preview 'bat --color=always --style=numbers --line-range=:500 {}' | str join ' ')"
    }
  }
  # CTRL-R: Command history search
  {
    name: skim_history_search
    modifier: control
    keycode: char_r
    mode: [emacs, vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "commandline edit --replace (history | get command | reverse | sk --no-sort --tac | str trim)"
    }
  }
  # ALT-C: Directory navigation
  {
    name: skim_directory_cd
    modifier: alt
    keycode: char_c
    mode: [emacs, vi_normal, vi_insert]
    event: {
      send: executehostcommand
      cmd: "cd (fd --type d --hidden --follow --exclude .git | sk --preview 'ls -la {}' | str trim)"
    }
  }
]

# ============================================================================
# Git worktree integration with git-crypt support
# ============================================================================

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

  # Verify status
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

  # Get PR branch name from GitHub
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

  # Check for git-crypt
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

  # Verify status
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

  # Delete the branch if it exists
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

# Aliases for git-worktree functions
alias gwnew = git-worktree-new
alias gwpr = git-worktree-pr
alias gwcd = git-worktree-cd
alias gwprune = git-worktree-prune

# ============================================================================
# GitHub CLI helpers
# ============================================================================

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

# ============================================================================
# GitHub CLI + skim interactive pickers
# ============================================================================

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

# ============================================================================
# System maintenance and cleanup utilities
# ============================================================================

def cleanup-cache [] {
  print "This will cleanup cache older than 6 months. Are you sure? [y/N]"
  let response = input

  if ($response | str downcase) in ["y", "yes"] {
    ^find ~/.cache/ -depth -type f -atime +182 -delete
    print "✓ Cache cleanup complete"
  } else {
    print "Cancelled"
  }
}

def cleanup-ds-store [] {
  ^fd -IH .DS_Store -x rm -f
  print "✓ .DS_Store files removed"
}

def trash-empty [] {
  print "Empty Trash? [y/N]"
  let response = input

  if ($response | str downcase) in ["y", "yes"] {
    ^osascript -e 'tell app "Finder" to empty'
    print "✓ Trash emptied"
  } else {
    print "Cancelled"
  }
}
