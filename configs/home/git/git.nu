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
    if ($response | str downcase) not-in ["y" "yes"] {
      print "Cancelled"
      return
    }
    rm -f $lefthook_file
  }

  ^cp -L $template $lefthook_file
  print $"📝 Created lefthook.yml"

  lefthook install
  print $"✅ Lefthook installed in ($repo_root)"
}

def worktree-names [] {
  let repo_root = try {
    ^git rev-parse --show-toplevel | str trim
  } catch {
    return []
  }

  let worktrees_dir = $"($repo_root)/.worktrees"

  if not ($worktrees_dir | path exists) {
    return []
  }

  ls $worktrees_dir | get name | path basename
}

def pr-numbers [] {
  try {
    ^gh pr list --json number,title --limit 50
    | from json
    | each {|pr| {value: ($pr.number | into string) description: $pr.title} }
  } catch {
    []
  }
}

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

# TODO: copy .local_scripts and lefthook.yml
def --env git-worktree-pr [pr_number: int@pr-numbers] {
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
  ^git fetch origin $"pull/($pr_number)/head:($pr_branch)" | lines | where {|line| not ($line | str starts-with "From") }

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

def git-worktree-prune [branch_name: string@worktree-names] {
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

def --env git-worktree-cd [branch_name: string@worktree-names] {
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

alias gsw = git sw
alias gwcd = git-worktree-cd
alias gwnew = git-worktree-new
alias gwpr = git-worktree-pr
alias gwprune = git-worktree-prune
