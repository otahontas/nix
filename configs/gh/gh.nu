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
