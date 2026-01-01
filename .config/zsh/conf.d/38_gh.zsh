# GitHub CLI + fzf helpers

# === Shared helpers (private) ===
function _gh_fzf_require_commands() {
    local missing=0 cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'gh.fzf: missing required command: %s\n' "$cmd" >&2
            missing=1
        fi
    done
    return $missing
}

function _gh_fzf_trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

function _gh_fzf_get_field() {
    local line="$1"
    local index="$2"
    local IFS='|'
    local -a fields
    read -rA fields <<< "$line"
    if (( index < 1 || index > ${#fields[@]} )); then
        return 1
    fi
    local field="${fields[$index]}"
    _gh_fzf_trim "$field"
}

function _gh_fzf_populate_buffer() {
    local command_line="$1"
    if [[ -n $command_line ]]; then
        print -z -- "$command_line"
    fi
}

function _gh_fzf_select() {
    _gh_fzf_require_commands fzf || return 1
    local prompt="$1"
    local header="$2"
    shift 2
    local -a args
    args=(--no-multi)
    [[ -n $prompt ]] && args+=(--prompt "${prompt}> ")
    [[ -n $header ]] && args+=(--header "$header")
    args+=("$@")
    fzf "${args[@]}"
}

# === Pull request helpers (private) ===
function _gh_fzf_list_prs() {
    _gh_fzf_require_commands gh || return 1
    local mode="$1"
    local jq_filter
    jq_filter=$(
        cat <<'EOF'
map("\(.number) | \(.title | gsub("\n"; " ")) | \(.headRefName) | \(.createdAt | fromdateiso8601 | strftime("%Y-%m-%d %H:%M"))") | .[]
EOF
    )
    local -a cmd
    cmd=(gh pr list --state open --limit 100)
    case "$mode" in
        mine) cmd+=(--author "@me") ;;
        review) cmd+=(--search "review-requested:@me") ;;
    esac
    cmd+=(--json number,title,headRefName,createdAt --jq "$jq_filter")
    setopt localoptions pipefail
    "${cmd[@]}"
}

function _gh_fzf_pick_pr() {
    local mode="$1"
    local prompt="$2"
    local selection
    setopt localoptions pipefail
    selection=$(_gh_fzf_list_prs "$mode" | _gh_fzf_select "$prompt" "id | title | branch | created at") || return 1
    [[ -z $selection ]] && return 1
    _gh_fzf_get_field "$selection" 1
}

# === Run helpers (private) ===
function _gh_fzf_list_runs() {
    _gh_fzf_require_commands gh || return 1
    local jq_filter
    jq_filter=$(
        cat <<'EOF'
def fmt_interval($secs):
  if ($secs == null) or ($secs < 0) then "-"
  else
    ($secs | floor) as $total |
    ($total / 86400 | floor) as $d |
    (($total % 86400) / 3600 | floor) as $h |
    (($total % 3600) / 60 | floor) as $m |
    ($total % 60) as $s |
    if $d > 0 then "\($d)d\($h)h"
    elif $h > 0 then "\($h)h\($m)m"
    elif $m > 0 then "\($m)m\($s)s"
    else "\($s)s"
    end
  end;
def fmt_age($ts):
  if $ts == null then "-"
  else fmt_interval(now - ($ts | fromdateiso8601))
  end;
def fmt_elapsed($start; $updated; $conclusion):
  if $start == null then "-"
  else
    ($start | fromdateiso8601) as $s |
    (if $conclusion == null then now else ($updated | fromdateiso8601 // now) end - $s) as $diff |
    fmt_interval($diff)
  end;
map("\(.status) | \(.displayTitle) | \(.workflowName // "-") | \(.headBranch // "-") | \(.databaseId) | \(fmt_elapsed(.startedAt; .updatedAt; .conclusion)) | \(fmt_age(.createdAt))") | .[]
EOF
    )
    setopt localoptions pipefail
    gh run list --limit 50 --json status,displayTitle,workflowName,headBranch,databaseId,startedAt,updatedAt,createdAt,conclusion \
        --jq "$jq_filter"
}

function _gh_fzf_pick_run() {
    local selection
    setopt localoptions pipefail
    selection=$(_gh_fzf_list_runs | _gh_fzf_select "runs" "status | title | workflow | branch | id | elapsed | age") || return 1
    [[ -z $selection ]] && return 1
    _gh_fzf_get_field "$selection" 5
}

# === Public helpers ===
function gh-pr-review-all() {
    local pr_number
    pr_number=$(_gh_fzf_pick_pr all "review (all)") || return 0
    [[ -z $pr_number ]] && return 0
    _gh_fzf_populate_buffer "gh pr view --comments $pr_number"
}

function gh-pr-review-mine() {
    local pr_number
    pr_number=$(_gh_fzf_pick_pr mine "review (mine)") || return 0
    [[ -z $pr_number ]] && return 0
    _gh_fzf_populate_buffer "gh pr view --comments $pr_number"
}

function gh-pr-review-others() {
    local pr_number
    pr_number=$(_gh_fzf_pick_pr review "review (others)") || return 0
    [[ -z $pr_number ]] && return 0
    _gh_fzf_populate_buffer "gh pr view --comments $pr_number"
}

function gh-pr-approve-and-merge() {
    local pr_number
    pr_number=$(_gh_fzf_pick_pr all "approve+merge") || return 0
    [[ -z $pr_number ]] && return 0
    _gh_fzf_populate_buffer "gh pr review $pr_number --approve && gh pr merge $pr_number --auto"
}

function gh-run-view() {
    local run_id
    run_id=$(_gh_fzf_pick_run) || return 0
    [[ -z $run_id ]] && return 0
    _gh_fzf_populate_buffer "gh run view $run_id"
}

function gh-pr-copy-url() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "Error: gh CLI not found" >&2
        return 1
    fi

    if ! command -v pbcopy >/dev/null 2>&1; then
        echo "Error: Clipboard tool pbcopy not available" >&2
        return 1
    fi

    if ! command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Not inside a git repository" >&2
        return 1
    fi

    local pr_url
    pr_url=$(gh pr view --json url --jq .url 2>/dev/null) || true

    if [[ -z $pr_url ]]; then
        echo "Error: No pull request found for the current branch" >&2
        return 1
    fi

    printf '%s' "$pr_url" | pbcopy
    echo "Copied PR URL to clipboard: $pr_url"
}
