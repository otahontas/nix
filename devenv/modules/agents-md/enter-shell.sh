#!/usr/bin/env bash
set -euo pipefail

# Replace a symlink, cleaning up macOS " 2", " 3" duplicates first.
# Only removes symlinks — never touches regular files.
safe_ln() {
  local src="$1" dest="$2"
  local dir base name ext

  dir="$(dirname "$dest")"
  base="$(basename "$dest")"

  # Remove target if it's a symlink
  [ -L "$dest" ] && rm "$dest"

  # Build name/ext for duplicate pattern
  if [[ $base == *.* ]]; then
    name="${base%.*}"
    ext=".${base##*.}"
  else
    name="$base"
    ext=""
  fi

  # Remove "name N.ext" duplicate symlinks in same dir
  find "$dir" -maxdepth 1 -type l \
    \( -name "${name} ${ext}" -o -name "${name} [0-9]*${ext}" \) \
    -delete 2>/dev/null || true

  ln -s "$src" "$dest"
}

agents_md_file="$1"

mkdir -p "${DEVENV_ROOT}/.pi/agent"
safe_ln "$agents_md_file" "${DEVENV_ROOT}/.pi/agent/AGENTS.md"
