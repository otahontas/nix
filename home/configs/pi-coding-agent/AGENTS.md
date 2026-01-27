# Pi coding agent nix configuration

This folder manages pi setup through nix home-manager.

## Structure

- `default.nix` - Main config with auto-discovery logic
- `sources/GLOBAL_AGENTS.md` - Source for global `~/.pi/agent/AGENTS.md`
- `skills/` - Simple skills (auto-discovered, symlinked to `~/.pi/agent/skills/`)
- `skills-with-deps/` - Skills with npm dependencies (need `buildNpmPackage`)
- `extensions/` - Extensions (auto-discovered `.ts` files)

## Adding new skills

**Simple skills (no npm deps):**

1. Create `skills/skillname/SKILL.md`
2. Stage: `git add skills/skillname/`
3. Run `just apply-home`

**Skills with dependencies:**

1. Create `skills-with-deps/skillname/` with `package.json` and `SKILL.md`
2. Add `buildNpmPackage` derivation in `default.nix`
3. Add symlink: `".pi/agent/skills/skillname".source = skillname-skill;`
4. Stage and run `just apply-home`

## Adding extensions

1. Create `extensions/name.ts`
2. Stage: `git add extensions/name.ts`
3. Run `just apply-home`

Extensions are auto-discovered - no need to edit `default.nix`.

## Modifying global AGENTS.md

Edit `sources/GLOBAL_AGENTS.md`, then run `just apply-home`.
