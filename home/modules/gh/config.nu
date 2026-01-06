# Format seconds into human-readable duration (e.g., "5m30s", "2h15m")
def format-duration [secs: int] {
  if $secs >= 86400 {
    $"($secs / 86400)d($secs mod 86400 / 3600)h"
  } else if $secs >= 3600 {
    $"($secs / 3600)h($secs mod 3600 / 60)m"
  } else if $secs >= 60 {
    $"($secs / 60)m($secs mod 60)s"
  } else {
    $"($secs)s"
  }
}

# Interactively select an open PR, returns PR number or null if cancelled
def gh-pr-select [prompt: string] {
  let prs = ^gh pr list --state open --limit 100 --json number,title,headRefName,createdAt | from json

  if ($prs | is-empty) {
    print "No open pull requests found"
    return null
  }

  let formatted = $prs | each {|pr|
      let created = ($pr.createdAt | into datetime | format date "%Y-%m-%d %H:%M")
      $"($pr.number) | ($pr.title) | ($pr.headRefName) | ($created)"
    }

  let selection = $formatted | str join "\n" | sk --prompt $prompt --header "id | title | branch | created at"

  if ($selection | is-empty) {
    return null
  }

  $selection | split row " | " | first | str trim | into int
}

# Get the URL of the current branch's pull request
def gh-pr-get-url [] {
  try {
    ^gh pr view --json url --jq .url | str trim
  } catch {
    error make {msg: "No pull request found for the current branch"}
  }
}

# Copy the current branch's PR URL to clipboard
def gh-pr-copy-url [] {
  let pr_url = gh-pr-get-url
  $pr_url | pbcopy
  print $"Copied PR URL to clipboard: ($pr_url)"
}

# Get the URL of the current git repository
def gh-repo-get-url [] {
  try {
    ^gh repo view --json url --jq .url | str trim
  } catch {
    error make {msg: "Could not get repository URL"}
  }
}

# Copy the current repository URL to clipboard
def gh-repo-copy-url [] {
  let repo_url = gh-repo-get-url
  $repo_url | pbcopy
  print $"Copied repo URL to clipboard: ($repo_url)"
}

# Interactively select and view an open PR with comments
def gh-pr-review [] {
  let pr_number = gh-pr-select "review> "
  if $pr_number == null { return }
  ^gh pr view --comments $pr_number
}

# Interactively select, approve, and auto-merge an open PR
def gh-pr-approve-and-merge [] {
  let pr_number = gh-pr-select "approve+merge> "
  if $pr_number == null { return }
  print $"Approving PR #($pr_number)..."
  ^gh pr review $pr_number --approve
  print $"Merging PR #($pr_number)..."
  ^gh pr merge $pr_number --auto
}

# Interactively select and view a GitHub Actions workflow run
def gh-run-view [] {
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
        let end = if ($run.conclusion | is-empty) { date now } else { $run.updatedAt | into datetime }
        format-duration (($end - $start) / 1sec | into int)
      }

      let age = if ($run.createdAt | is-empty) {
        "-"
      } else {
        format-duration ((date now) - ($run.createdAt | into datetime) | / 1sec | into int)
      }

      let workflow = $run.workflowName | default "-"
      let branch = $run.headBranch | default "-"

      $"($run.status) | ($run.displayTitle) | ($workflow) | ($branch) | ($run.databaseId) | ($elapsed) | ($age)"
    }

  let selection = $formatted | str join "\n" | sk --prompt "runs> " --header "status | title | workflow | branch | id | elapsed | age"

  if ($selection | is-empty) {
    return
  }

  let run_id = $selection | split row " | " | get 4 | str trim | into int
  ^gh run view $run_id
}

# Format a release PR's notes for Slack and copy to clipboard
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

  let output = $"Released ($service) `($version)\n\n($release_notes)"
  print $output
  $output | pbcopy
  print -e "Copied to clipboard."
}
