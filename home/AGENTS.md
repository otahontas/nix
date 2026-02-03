home-manager user-level config for macOS, includes:

- User environment settings
- Tool configurations (in `./configs`) for shells, CLI tools, editor etc.
- Catppuccin theme (macchiato flavor, blue accent)

Applied per-user, no admin privileges needed.
When applying use `devenv tasks run home:apply` from repo root.
If you add new files to configuration, you need to stage them before applying.
Don't stage modified files, just new ones.
Don't commit unless asked.

## Configuration patterns

**Home manager preferred:** Always use `programs` or `services` through home-manager, fallback to `pkgs`.

**Auto-import**: All `.nix` files in `./configs/` are automatically imported via `lib.filesystem.listFilesRecursive` - no manual module listing needed.

**One tool per directory**: Each `configs/` subdirectory manages one tool with `default.nix` as main config. Additional files (scripts, configs) placed alongside and referenced from default.nix.

**Fish shell integration**: Each tool owns its shell integration in its own config:

- Shell aliases → always use `shellAliases`
- Interactive shell init → always via `builtins.readFile` from external file(s), never inline strings
- Completions → add completions via `fish/conf.d/` using `xdg.configFile."fish/conf.d/<tool>.fish".text = builtins.readFile ./<tool>.fish;` (avoid `fish/completions/<cmd>.fish` unless you want to replace upstream/vendor completions; fish loads the first match on `$fish_complete_path`)
- Functions → always with `description` and `body` from external file

**GUI apps**: Prefer home-manager when nixpkgs has darwin support with `.app` bundle:

- `targets.darwin.copyApps.enable = true` (works with Spotlight)
- Security/system apps can live here when packaged as `.app` bundles
- Mac App Store apps stay in masApps

**LaunchAgents**: Auto-start apps via `launchd.agents` module.

**Session variables**: Always use session variables for paths and environment config.
