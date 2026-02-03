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
3. Run `devenv tasks run home:apply`

**Skills with dependencies:**

1. Create `skills-with-deps/skillname/` with `package.json` and `SKILL.md`
2. Add `buildNpmPackage` derivation in `default.nix`
3. Add symlink: `".pi/agent/skills/skillname".source = skillname-skill;`
4. Stage and run `devenv tasks run home:apply`

## Adding extensions

1. Create `extensions/name.ts`
2. Stage: `git add extensions/name.ts`
3. Run `devenv tasks run home:apply`

Extensions are auto-discovered, so you usually do not need to edit `default.nix`.

## Opt-in extensions (example: Neovim bridge)

Pi auto-loads anything in `~/.pi/agent/extensions/`. For workflow-specific or “only one instance should run this” extensions (like the Neovim bridge), keep them opt-in.

How this repo does opt-in loading:

- Exclude the extension from auto-discovery
  - add `nvim-bridge.ts` to `disabledExtensions` in `default.nix`
  - this prevents it from being symlinked into `~/.pi/agent/extensions/`
- Still install the extension, but into a non-auto-loaded location
  - `~/.pi/agent/extensions-opt/nvim-bridge.ts`
- Provide a wrapper command that loads it explicitly
  - `pinvim` runs `pi` with `-e ~/.pi/agent/extensions-opt/nvim-bridge.ts`
  - use `pi` for normal sessions (no syncing)
  - use `pinvim` for the one session that should sync to Neovim

## Modifying global AGENTS.md

Edit `sources/GLOBAL_AGENTS.md`, then run `devenv tasks run home:apply`.
