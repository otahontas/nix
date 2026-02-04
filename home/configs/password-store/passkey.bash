#!/usr/bin/env bash
# pass-passkey - A pass extension to find accounts that support passkey login
#
# Usage: pass passkey [--refresh] [--verbose]
#
# This extension scans your password store entries and checks which ones
# have passkey support according to the passkeys.2fa.directory API.

set -euo pipefail

VERSION="1.0.1"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pass-passkey"
CACHE_FILE="$CACHE_DIR/supported.json"
CACHE_MAX_AGE=86400 # 24 hours in seconds

API_URL="https://passkeys-api.2fa.directory/v1/supported.json"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  CYAN=$'\033[0;36m'
  BOLD=$'\033[1m'
  RESET=$'\033[0m'
else
  GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' RESET=''
fi

VERBOSE=0
REFRESH=0

usage() {
  cat <<EOF
Usage: pass passkey [OPTIONS]

Scan your password store for accounts that support passkey authentication.

Mark entries with "passkey: enabled" to show passkey status.

Options:
    --refresh, -r    Force refresh of the passkey directory cache
    --verbose, -v    Show additional details (passwordless/MFA support)
    --help, -h       Show this help message
    --version        Show version

The passkey directory data is cached for 24 hours.
Data source: https://passkeys.2fa.directory
EOF
}

log_verbose() {
  if [[ $VERBOSE -eq 1 ]]; then
    printf '%s\n' "$*" >&2
  fi
}

sanitize_output() {
  printf '%s' "$1" | LC_ALL=C tr -d '[:cntrl:]'
}

entry_has_passkey_enabled() {
  local entry="$1"

  if pass show "$entry" 2>/dev/null | grep -qiE '^passkey:[[:space:]]*enabled([[:space:]]*$|[[:space:]]+)'; then
    return 0
  fi

  return 1
}

# Extract the main domain from a path
# e.g., "email/mail.google.com/user" -> "google.com"
# e.g., "social/twitter.com" -> "twitter.com"
extract_domain() {
  local path="$1"
  local part

  # Try each path component to find something that looks like a domain
  IFS='/' read -ra parts <<<"$path"
  for part in "${parts[@]}"; do
    # Check if it looks like a domain (contains a dot, no spaces)
    if [[ $part == *.* && $part != *" "* ]]; then
      # Remove common subdomains to get base domain
      # Handle cases like mail.google.com, www.example.com, login.service.com
      local domain="$part"

      # Extract base domain (last two parts, or three for co.uk etc.)
      local base
      if [[ $domain =~ \.(co|com|org|net|gov)\.[a-z]{2}$ ]]; then
        # Handle .co.uk, .com.au, etc.
        base=$(echo "$domain" | rev | cut -d. -f1-3 | rev)
      else
        # Standard TLD
        base=$(echo "$domain" | rev | cut -d. -f1-2 | rev)
      fi
      echo "$base"
      return
    fi
  done

  # Fallback: return the last component if nothing matched
  echo "${parts[-1]}"
}

# Ensure cache directory exists with restrictive permissions
ensure_cache_dir() {
  mkdir -p "$CACHE_DIR"
  chmod 700 "$CACHE_DIR"
}

# Check if cache is valid
cache_is_valid() {
  if [[ ! -f $CACHE_FILE ]]; then
    return 1
  fi

  local cache_age
  local now
  now=$(date +%s)
  cache_age=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)

  if ((now - cache_age > CACHE_MAX_AGE)); then
    return 1
  fi

  return 0
}

# Fetch passkey directory data
fetch_passkey_data() {
  ensure_cache_dir

  log_verbose "Fetching passkey directory from API..."

  local tmpfile
  tmpfile=$(mktemp "$CACHE_DIR/supported.XXXXXX")
  # shellcheck disable=SC2064
  trap "rm -f '$tmpfile'" EXIT

  if ! curl -sf --connect-timeout 5 --max-time 20 --retry 2 --retry-delay 1 "$API_URL" -o "$tmpfile"; then
    echo "Error: Failed to fetch passkey directory data" >&2
    rm -f "$tmpfile"
    if [[ -f $CACHE_FILE ]]; then
      echo "Using stale cache..." >&2
      return 0
    fi
    return 1
  fi

  # Validate response is valid JSON
  if ! jq empty "$tmpfile" 2>/dev/null; then
    echo "Error: Invalid JSON response from API" >&2
    rm -f "$tmpfile"
    if [[ -f $CACHE_FILE ]]; then
      echo "Using stale cache..." >&2
      return 0
    fi
    return 1
  fi

  mv "$tmpfile" "$CACHE_FILE"
  trap - EXIT
  log_verbose "Cache updated."
}

# Get passkey data (from cache or fresh)
get_passkey_data() {
  if [[ $REFRESH -eq 1 ]] || ! cache_is_valid; then
    fetch_passkey_data
  else
    log_verbose "Using cached passkey directory."
  fi

  cat "$CACHE_FILE"
}

# Main function
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --refresh | -r)
      REFRESH=1
      shift
      ;;
    --verbose | -v)
      VERBOSE=1
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    --version)
      echo "pass-passkey v$VERSION"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    esac
  done

  # Check dependencies
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
  fi

  if ! command -v curl &>/dev/null; then
    echo "Error: curl is required but not installed." >&2
    exit 1
  fi

  # Get password store path
  local prefix="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

  if [[ ! -d $prefix ]]; then
    echo "Error: Password store not found at $prefix" >&2
    exit 1
  fi

  # Get all pass entries
  log_verbose "Scanning password store at $prefix..."

  local entries=()
  while IFS= read -r -d '' file; do
    # Remove prefix and .gpg extension
    local entry="${file#"$prefix"/}"
    entry="${entry%.gpg}"
    entries+=("$entry")
  done < <(find "$prefix" -name "*.gpg" -type f -print0 2>/dev/null)

  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "No entries found in password store." >&2
    exit 0
  fi

  log_verbose "Found ${#entries[@]} entries in password store."

  # Fetch passkey data
  local passkey_data
  if ! passkey_data=$(get_passkey_data); then
    exit 1
  fi

  # Extract all supported domains from API
  local supported_domains
  supported_domains=$(echo "$passkey_data" | jq -r 'keys[]')

  # Build associative array for quick lookup
  declare -A passkey_info
  while IFS= read -r domain; do
    local info
    info=$(echo "$passkey_data" | jq -r --arg d "$domain" '.[$d] | "\(.passwordless // "no")|\(.mfa // "no")"')
    passkey_info["$domain"]="$info"
  done <<<"$supported_domains"

  # Check each entry
  local found=0
  local matches=()

  for entry in "${entries[@]}"; do
    local domain
    domain=$(extract_domain "$entry")

    # Check if domain or any variation matches
    if [[ -n ${passkey_info[$domain]:-} ]]; then
      local info="${passkey_info[$domain]}"
      local passwordless="${info%|*}"
      local mfa="${info#*|}"

      local safe_entry
      local safe_domain
      safe_entry=$(sanitize_output "$entry")
      safe_domain=$(sanitize_output "$domain")

      local enabled_label=""
      if entry_has_passkey_enabled "$entry"; then
        enabled_label=" ${CYAN}(passkey enabled)${RESET}"
      fi

      local details=""
      if [[ $VERBOSE -eq 1 ]]; then
        local safe_passwordless
        local safe_mfa
        safe_passwordless=$(sanitize_output "$passwordless")
        safe_mfa=$(sanitize_output "$mfa")

        local features=()
        [[ $passwordless != "no" ]] && features+=("passwordless: $safe_passwordless")
        [[ $mfa != "no" ]] && features+=("mfa: $safe_mfa")
        if [[ ${#features[@]} -gt 0 ]]; then
          local feature_list
          feature_list=$(printf '%s, ' "${features[@]}")
          feature_list=${feature_list%, }
          details=" ${CYAN}(${feature_list})${RESET}"
        fi
      fi

      matches+=("${GREEN}✓${RESET} ${BOLD}${safe_entry}${RESET} ${YELLOW}→${RESET} ${safe_domain}${enabled_label}${details}")
      ((found++))
    fi
  done

  # Print results
  printf '%s\n' "${BOLD}Passkey Scanner Results${RESET}"
  printf '%s\n' "━━━━━━━━━━━━━━━━━━━━━━━━"
  printf '\n'

  if [[ $found -eq 0 ]]; then
    printf '%s\n' "No accounts with passkey support found."
    printf '\n'
    printf '%s\n' "${BLUE}Tip:${RESET} Check https://passkeys.2fa.directory for the full list"
    printf '%s\n' "of sites that support passkeys."
  else
    printf '%s\n' "Found ${GREEN}${BOLD}$found${RESET} account(s) that support passkey login:"
    printf '\n'
    for match in "${matches[@]}"; do
      printf '%s\n' "  $match"
    done
    printf '\n'
    printf '%s\n' "${BLUE}Tip:${RESET} Consider setting up passkeys for these accounts to improve security."
  fi
}

# Run if executed directly or as pass extension
main "$@"
