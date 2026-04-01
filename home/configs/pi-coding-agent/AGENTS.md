## Structure

- `default.nix` - Main config with auto-discovery logic
- `sources/GLOBAL_AGENTS.md` - Source for global `~/.pi/agent/AGENTS.md`
- `skills/` - Simple skills (auto-discovered, symlinked to `~/.pi/agent/skills/`)
- `extensions/` - Extensions (auto-discovered `.ts` files)

## Adding new skills

1. Create `skills/skillname/SKILL.md`
2. Stage: `git add skills/skillname/`
3. Run `devenv tasks run home:apply`

## Adding extensions

1. Create `extensions/name.ts`
2. Stage: `git add extensions/name.ts`
3. Run `devenv tasks run home:apply`

Extensions are auto-discovered, so you usually do not need to edit `default.nix`.
