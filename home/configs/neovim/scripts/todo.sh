#!/usr/bin/env bash
set -euo pipefail

p=$(todo_path) || exit 1
nvim "$p"
