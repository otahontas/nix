#!/bin/sh
# LLM check module - uses llm CLI to detect sensitive information

run_llm_check() {
    echo "🤖 Running llm sensitive data check..."

    if ! command -v llm >/dev/null 2>&1; then
        echo "⚠️  llm not found, skipping"
        return 0
    fi

    # Check for sensitive information using llm
    SENSITIVE_INFO=$(git diff --cached | llm -s "Describe any sensitive information, personal data, or secrets in this diff. If none, output 'nothing' and nothing else.")

    if [ "$SENSITIVE_INFO" != "nothing" ]; then
        echo "❌ llm detected the following sensitive information:"
        echo "$SENSITIVE_INFO"
        return 1
    fi

    echo "✅ llm check passed"
    return 0
}
