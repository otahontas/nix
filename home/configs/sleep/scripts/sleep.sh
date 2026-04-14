#!/usr/bin/env bash
set -euo pipefail

case "$(basename "$0")" in
disable-sleep) sudo pmset -a disablesleep 1 ;;
enable-sleep) sudo pmset -a disablesleep 0 ;;
esac
