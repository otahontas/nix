# Pi coding agent nix configuration

This folder manages pi setup through nix home-manager.

## Structure

- `default.nix` - Main config that symlinks everything to `~/.pi/agent/`
- `sources/GLOBAL_AGENTS.md` - Source for global `~/.pi/agent/AGENTS.md`
- `skills/*/SKILL.md` - Pi skills (symlinked to `~/.pi/agent/skills/`)
- `extensions/*.ts` - Pi extensions (symlinked to `~/.pi/agent/extensions/`)

## Adding new skills

1. Create skill in `skills/skillname/SKILL.md`
2. Add to `default.nix` under `home.file`:
   ```nix
   ".pi/agent/skills/skillname/SKILL.md".source = ./skills/skillname/SKILL.md;
   ```
3. Run `just apply` to activate

Skills with dependencies (like brave-search) need a `buildNpmPackage` derivation in `default.nix`.

## Adding extensions

1. Create extension in `extensions/name.ts`
2. Add to `default.nix`:
   ```nix
   ".pi/agent/extensions/name.ts".source = ./extensions/name.ts;
   ```
3. Run `just apply`

## Modifying global AGENTS.md

Edit `sources/GLOBAL_AGENTS.md`, then run `just apply`.
