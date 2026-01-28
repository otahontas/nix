#!/usr/bin/env bash
# Merge enabledModels into settings.json without touching other keys
# This script is idempotent and preserves all other settings

set -euo pipefail

SETTINGS_FILE="${HOME}/.pi/agent/settings.json"
MODELS_JSON="$1" # Path to file containing just the enabledModels array

# Create settings directory if it doesn't exist
mkdir -p "$(dirname "$SETTINGS_FILE")"

# If settings.json doesn't exist, create minimal config
if [[ ! -f $SETTINGS_FILE ]]; then
  echo '{}' >"$SETTINGS_FILE"
fi

# Use jq to merge only the enabledModels key
# This preserves all other keys and only updates/adds enabledModels
jq --argjson models "$(cat "$MODELS_JSON")" \
  '.enabledModels = $models' \
  "$SETTINGS_FILE" >"${SETTINGS_FILE}.tmp"

mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
