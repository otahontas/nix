# Format seconds into human-readable duration (e.g., "5m30s", "2h15m")
function format-duration
    set -l secs $argv[1]
    if test $secs -ge 86400
        set -l days (math "$secs / 86400")
        set -l hours (math "$secs % 86400 / 3600")
        echo "$days"d"$hours"h
    else if test $secs -ge 3600
        set -l hours (math "$secs / 3600")
        set -l mins (math "$secs % 3600 / 60")
        echo "$hours"h"$mins"m
    else if test $secs -ge 60
        set -l mins (math "$secs / 60")
        set -l remainder (math "$secs % 60")
        echo "$mins"m"$remainder"s
    else
        echo "$secs"s
    end
end

# Interactively select an open PR, returns PR number or empty if cancelled
function gh-pr-select
    set -l prompt $argv[1]
    set -l prs (gh pr list --state open --limit 100 --json number,title,headRefName,createdAt)

    if test -z "$prs" -o "$prs" = "[]"
        echo "No open pull requests found" >&2
        return 1
    end

    set -l formatted (echo $prs | jq -r '.[] | "\(.number) | \(.title) | \(.headRefName) | \(.createdAt | split("T")[0] + " " + .createdAt | split("T")[1] | split(".")[0])"')

    set -l selection (echo $formatted | fzf --prompt "$prompt" --header "id | title | branch | created at")

    if test -z "$selection"
        return 1
    end

    echo $selection | cut -d'|' -f1 | string trim
end

# Get the URL of the current branch's pull request
function gh-pr-get-url
    set -l url (gh pr view --json url --jq .url 2>/dev/null)
    if test -z "$url"
        echo "No pull request found for the current branch" >&2
        return 1
    end
    echo $url
end

# Copy the current branch's PR URL to clipboard
function gh-pr-copy-url
    set -l pr_url (gh-pr-get-url)
    or return 1
    echo $pr_url | pbcopy
    echo "Copied PR URL to clipboard: $pr_url"
end

# Get the URL of the current git repository
function gh-repo-get-url
    set -l url (gh repo view --json url --jq .url 2>/dev/null)
    if test -z "$url"
        echo "Could not get repository URL" >&2
        return 1
    end
    echo $url
end

# Copy the current repository URL to clipboard
function gh-repo-copy-url
    set -l repo_url (gh-repo-get-url)
    or return 1
    echo $repo_url | pbcopy
    echo "Copied repo URL to clipboard: $repo_url"
end

# Interactively select and view an open PR with comments
function gh-pr-review
    set -l pr_number (gh-pr-select "review> ")
    or return 1
    gh pr view --comments $pr_number
end

# Interactively select, approve, and auto-merge an open PR
function gh-pr-approve-and-merge
    set -l pr_number (gh-pr-select "approve+merge> ")
    or return 1
    echo "Approving PR #$pr_number..."
    gh pr review $pr_number --approve
    echo "Merging PR #$pr_number..."
    gh pr merge $pr_number --auto
end

# Interactively select and view a GitHub Actions workflow run
function gh-run-view
    set -l runs (gh run list --limit 50 --json status,displayTitle,workflowName,headBranch,databaseId,startedAt,updatedAt,createdAt,conclusion)

    if test -z "$runs" -o "$runs" = "[]"
        echo "No workflow runs found"
        return
    end

    set -l formatted (echo $runs | jq -r '.[] | 
        (.status) + " | " + 
        (.displayTitle) + " | " + 
        (.workflowName // "-") + " | " + 
        (.headBranch // "-") + " | " + 
        (.databaseId | tostring) + " | " + 
        (if .startedAt == null or .startedAt == "" then "-" else .startedAt end) + " | " + 
        (if .createdAt == null or .createdAt == "" then "-" else .createdAt end)')

    set -l selection (echo $formatted | fzf --prompt "runs> " --header "status | title | workflow | branch | id | started | created")

    if test -z "$selection"
        return
    end

    set -l run_id (echo $selection | cut -d'|' -f5 | string trim)
    gh run view $run_id
end

# Format a release PR's notes for Slack and copy to clipboard
function gh-release-slack
    set -l pr_number $argv[1]

    if test -z "$pr_number"
        echo "Usage: gh-release-slack <pr_number>" >&2
        return 1
    end

    set -l pr_data (gh pr view $pr_number --json title,body --template '{{ .title }}
{{ .body }}' 2>/dev/null)

    if test -z "$pr_data"
        echo "Failed to read PR $pr_number." >&2
        return 1
    end

    set -l title (echo $pr_data | head -n1)
    set -l release_notes (echo $pr_data | tail -n +2)

    # Parse title with format "Release <service> <version>"
    set -l match (echo $title | string match -r '^Release\s+(.+?)\s+(\S+)$')

    if test -z "$match"
        echo "PR $pr_number title \"$title\" does not match \"Release <service> <version>\" format." >&2
        return 1
    end

    set -l service (echo $match[2] | string trim)
    set -l version $match[3]

    if test -z (echo $release_notes | string trim)
        echo "PR $pr_number release notes are empty." >&2
        return 1
    end

    set -l output "Released $service \`$version\`

$release_notes"
    echo $output
    echo $output | pbcopy
    echo "Copied to clipboard." >&2
end
