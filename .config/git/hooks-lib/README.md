# Modular Git Hooks System

A lightweight, shell-based modular git hooks system.

## Architecture

```
~/.config/git/
├── template/hooks/          # Templates for new repos (copied via git init)
│   ├── pre-commit
│   ├── commit-msg
│   └── prepare-commit-msg
├── hooks-lib/               # Shared hook modules (functions)
│   ├── commitlint.sh       # Validates conventional commits
│   ├── gitleaks.sh         # Detects secrets
│   ├── llm-check.sh        # AI-powered sensitive data check
│   └── gptcommit.sh        # AI-generated commit messages
└── commitlint/
    └── commitlint.config.mjs
```

## How It Works

1. **Template Setup**: `git config --global init.templatedir ~/.config/git/template`
2. **New Repos**: `git init` copies hooks from template
3. **Configuration**: Edit flags directly in `.git/hooks/` files
4. **Modular Execution**: Template hooks run enabled modules from `hooks-lib/`

## Configuration

Edit hook flags directly in each repo's `.git/hooks/` files:

**Pre-commit** (`.git/hooks/pre-commit`):
```bash
HOOK_GITLEAKS=1       # Detect secrets (gitleaks)
HOOK_LLM_CHECK=0      # AI-powered sensitive data check (llm CLI)
```

**Commit-msg** (`.git/hooks/commit-msg`):
```bash
HOOK_COMMITLINT=1     # Validate conventional commits
```

**Prepare-commit-msg** (`.git/hooks/prepare-commit-msg`):
```bash
HOOK_GPTCOMMIT=1      # AI-generated commit messages
```

## Default Configuration

Template defaults:
- ✅ `HOOK_GITLEAKS=1` - Check for secrets
- ❌ `HOOK_LLM_CHECK=0` - AI check (costs API tokens)
- ✅ `HOOK_COMMITLINT=1` - Validate conventional commits
- ✅ `HOOK_GPTCOMMIT=1` - Generate commit messages

## Adding Hooks to Existing Repos

```bash
# Option 1: Reinit (safe, just copies hooks)
cd your-repo
git init

# Option 2: Manual copy
cp ~/.config/git/template/hooks/* .git/hooks/
```

## Adding New Hook Modules

1. Create module in `~/.config/git/hooks-lib/your-module.sh`:
```bash
#!/bin/sh
run_your_module() {
    echo "🔧 Running your module..."
    # Your code here
    return 0  # 0 = success, 1 = failure
}
```

2. Add to appropriate template hook:
```bash
if [ "$HOOK_YOUR_MODULE" = "1" ]; then
    . "$HOOKS_LIB/your-module.sh"
    if ! run_your_module; then
        HOOK_FAILED=1
    fi
    echo ""
fi
```

3. Add flag to template hook and document in README

## Dependencies

- **gitleaks** (brew): Secret detection
- **commitlint** (brew): Conventional commits validation
- **llm** (brew/pip): AI-powered checks (optional)
- **gptcommit** (brew): AI commit messages (optional)

All tools gracefully skip if not installed.

## Troubleshooting

**Hooks not running?**
- Check `.git/hooks/` has executable files
- Run `git init` to copy from template

**Commitlint fails?**
- Config at `~/.config/commitlint/commitlint.config.mjs`
- Uses inline rules (no external dependencies)

**Want to skip hooks temporarily?**
```bash
git commit --no-verify -m "message"
```

## Philosophy

- **Simple**: Plain shell scripts, no frameworks
- **Modular**: Each check is isolated
- **Configurable**: Per-repo control
- **Transparent**: Easy to understand and debug
- **Optional**: Tools gracefully skip if missing
