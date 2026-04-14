#!/usr/bin/env bash
set -euo pipefail

p=$(daily_path) || exit 1
nvim "$p"
