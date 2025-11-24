#!/bin/sh
# GPTCommit module - generates commit messages with AI

run_gptcommit() {
    local commit_msg_file="$1"
    local commit_source="$2"
    local commit_sha="$3"

    # Skip if commit message already provided (git commit -m)
    if [ -n "$commit_source" ]; then
        return 0
    fi

    if ! command -v gptcommit >/dev/null 2>&1; then
        return 0
    fi

    gptcommit prepare-commit-msg --commit-msg-file "$commit_msg_file" --commit-source "$commit_source" --commit-sha "$commit_sha"
    exitCode=$?

    if [ $exitCode -ne 0 ]; then
        return 0
    fi

    # Keep only the first line (title), strip body
    # Save first non-comment line, then remove everything after it
    if [ -f "$commit_msg_file" ]; then
        # Get first non-comment, non-empty line
        first_line=$(grep -v '^#' "$commit_msg_file" | grep -v '^[[:space:]]*$' | head -1)

        # Rewrite file with just first line + git comments
        {
            echo "$first_line"
            echo ""
            grep '^#' "$commit_msg_file"
        } > "$commit_msg_file.tmp"

        mv "$commit_msg_file.tmp" "$commit_msg_file"
    fi

    return 0
}
