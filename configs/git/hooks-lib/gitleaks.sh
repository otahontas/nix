#!/bin/sh
# Gitleaks module - detects secrets in commits

run_gitleaks() {
    echo "🔍 Running gitleaks..."

    if ! command -v gitleaks >/dev/null 2>&1; then
        echo "⚠️  gitleaks not found, skipping"
        return 0
    fi

    gitleaks protect -v --staged
    exitCode=$?

    if [ $exitCode -eq 1 ]; then
        echo "❌ gitleaks detected sensitive information"
        return 1
    fi

    echo "✅ gitleaks passed"
    return 0
}
