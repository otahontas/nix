# TODO

- nix + password store setup for passwords
- safe-chain aikido setup
- .aws audit
- 1password cli -> trash
- Docker audit WARNING! Your credentials are stored unencrypted in '/Users/otahontas/.docker/config.json'. Configure a credential helper to remove this warning. See https://docs.docker.com/go/credential-store/
- better 
"make command X work" -> press something -> llm provides the correct cmd type of workflow

## Dotfiles to move to Nix
- Move .zshrc to Nix (create configs/zsh.nix)
- Merge .ssh/keys.conf into configs/ssh.nix
- Handle .npmrc - remove token, use env var or 1Password
- Expand AWS config in configs/awscli.nix (profiles without credentials)
