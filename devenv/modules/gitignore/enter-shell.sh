#!/usr/bin/env bash
set -euo pipefail

gitignore_file="$1"

if ! cmp -s "$gitignore_file" "$DEVENV_ROOT/.gitignore"; then
  chflags nouchg "$DEVENV_ROOT/.gitignore" 2>/dev/null || true
  install -m 444 "$gitignore_file" "$DEVENV_ROOT/.gitignore"
  chflags uchg "$DEVENV_ROOT/.gitignore"
fi
