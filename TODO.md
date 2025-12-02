# TODO

## Credential migration (in progress)
- [ ] Run migration scripts to move credentials to pass
  - `.local_scripts/setup-docker-credentials.nu`
  - `.local_scripts/setup-npm-token.nu`
- [ ] Apply configuration: `mise run verify && mise run apply`
- [ ] Rotate Docker and NPM tokens (exposed in plaintext)
  - See MIGRATION_CREDENTIALS.md for details

## Dotfiles to move to Nix
- Merge .ssh/keys.conf into configs/ssh.nix
