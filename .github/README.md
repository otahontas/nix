# dotfiles

Personal configuration files, heavily leaning on simple configs for neovim, zsh, wezterm, git.

## Setup on new machine

```bash
# Clone
git clone --bare git@github.com:otahontas/dotfiles.git $HOME/.dotfiles

# Add alias temporarily
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Get files
dotfiles checkout

# Hide untracked files
dotfiles config --local status.showUntrackedFiles no
```

## Daily use (with git aliases! out of the box!)

```bash
dotfiles s                # see changes
dotfiles a <file>         # track file
dotfiles cm "msg"         # save changes
dotfiles poh              # upload to origin HEAD (works with branches)
```

## How it works

Uses a bare git repo, so files stay in normal locations and there are no symlinks.

The `dotfiles` command is an alias that tells git to:

- Store metadata in `~/.dotfiles/`
- Track files in `~/`
