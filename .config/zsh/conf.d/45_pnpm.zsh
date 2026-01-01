# pnpm integration

# Completions (cached to avoid hitting pnpm on every shell start)
if command -v pnpm >/dev/null 2>&1; then
  zcache_source "pnpm/completion.zsh" --cwd "${HOME:-/}" -- pnpm completion zsh
fi
