#!/usr/bin/env bash
set -euo pipefail

secs=$1
if [ "$secs" -ge 86400 ]; then
  days=$((secs / 86400))
  hours=$((secs % 86400 / 3600))
  echo "${days}d${hours}h"
elif [ "$secs" -ge 3600 ]; then
  hours=$((secs / 3600))
  mins=$((secs % 3600 / 60))
  echo "${hours}h${mins}m"
elif [ "$secs" -ge 60 ]; then
  mins=$((secs / 60))
  remainder=$((secs % 60))
  echo "${mins}m${remainder}s"
else
  echo "${secs}s"
fi
