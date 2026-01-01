#!/bin/sh
# Commitlint module - validates conventional commit messages

run_commitlint() {
    local commit_msg_file="$1"

    echo "📝 Running commitlint..."

    if ! command -v commitlint >/dev/null 2>&1; then
        echo "⚠️  commitlint not found, skipping"
        return 0
    fi

    # Skip merge commits
    if grep -q "^Merge" "$commit_msg_file"; then
        echo "ℹ️  Merge commit detected, skipping commitlint"
        return 0
    fi

    # Run commitlint
    commitlint --config ~/.config/commitlint/commitlint.config.mjs --edit "$commit_msg_file"
    exitCode=$?

    if [ $exitCode -ne 0 ]; then
        echo "❌ commitlint failed"
        return 1
    fi

    echo "✅ commitlint passed"
    return 0
}
