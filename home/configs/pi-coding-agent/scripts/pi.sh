#!/usr/bin/env bash
set -euo pipefail

export PATH="@nodejs@/bin:@poppler_utils@/bin:@ast_grep@/bin:@lat_md@/bin:$PATH"

# Load API keys from pass
if command -v @pass@/bin/pass &>/dev/null; then
  GEMINI_API_KEY="$(@pass@/bin/pass show api/gemini-pi-coding-agent-web-search 2>/dev/null || true)"
  ZAI_API_KEY="$(@pass@/bin/pass show api/z-pi-coding-agent 2>/dev/null || true)"
  CONTEXT7_API_KEY="$(@pass@/bin/pass show api/context7 2>/dev/null || true)"
  GITHITS_API_KEY="$(@pass@/bin/pass show api/githits 2>/dev/null || true)"
  export GEMINI_API_KEY ZAI_API_KEY CONTEXT7_API_KEY GITHITS_API_KEY
fi
exec @pi_coding_agent@/bin/pi "$@"
