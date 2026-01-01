# System maintenance functions

# Auto-prompt helper (called from 99_startup-checks.zsh)
function _prompt_update_packages() {
    local timestamp_file="$XDG_DATA_HOME/update_packages_timestamp"
    local current_time=$(date +%s)
    local last_run=0

    # Read last run timestamp if file exists
    if [[ -f "$timestamp_file" ]]; then
        local read_result
        if read_result=$(cat "$timestamp_file" 2>&1); then
            # Validate it's a number
            if [[ "$read_result" =~ ^[0-9]+$ ]]; then
                last_run=$read_result
            else
                echo "⚠️  Warning: Invalid timestamp in $timestamp_file (found: '$read_result')" >&2
                echo "   Run 'update-packages' to reset the timestamp." >&2
                return 1
            fi
        else
            echo "⚠️  Warning: Failed to read timestamp file: $timestamp_file" >&2
            echo "   Error: $read_result" >&2
            return 1
        fi
    fi

    # Check if 24 hours (86400 seconds) have passed
    local time_diff=$((current_time - last_run))
    if [[ $time_diff -ge 86400 ]]; then
        if [[ $last_run -eq 0 ]]; then
            echo -n "Update packages? (First run) [y/N]: "
        else
            echo -n "Update packages? It's been $(($time_diff / 3600)) hours since last run. [y/N]: "
        fi
        read -r response

        case "$response" in
            [yY]|[yY][eE][sS])
                update-packages
                ;;
            *)
                echo "$current_time" > "$timestamp_file"
                ;;
        esac
    fi
}

# Check Homebrew bash is in /etc/shells (called from 99_startup-checks.zsh)
function _prompt_homebrew_bash() {
    local brew_bash="/opt/homebrew/bin/bash"

    # Skip if Homebrew bash doesn't exist
    [[ ! -x "$brew_bash" ]] && return

    if ! grep -qE "^${brew_bash}/?$" /etc/shells 2>/dev/null; then
        echo "⚠️  Homebrew bash not in /etc/shells. To add:"
        echo "   sudo sh -c 'echo $brew_bash >> /etc/shells'"
    fi
}

# System update function
function update-packages() {
  local LOG_FILE="${XDG_DATA_HOME}/system_update.log"
  local timestamp_file="$XDG_DATA_HOME/update_packages_timestamp"
  # `tee -a` appends to the log file while also printing to standard output.
  # `2>&1` redirects stderr to stdout, so both are captured.
  {
    echo "======================================================================"
    echo "Starting packages update at: $(date -u +"%Y-%m-%dT%H:%M:%SZ") (UTC)"
    echo "======================================================================"
    echo "\n🍺 Updating Homebrew formulas and casks..."
    if command -v brew &> /dev/null; then
      brew update
      brew upgrade --fetch-HEAD
      brew autoremove
      brew cleanup
    else
      echo "  Skipping: Homebrew (brew) not found."
    fi
    echo "\n🐙 Updating GitHub CLI extensions..."
    if command -v gh &> /dev/null; then
      gh extension upgrade --all
    else
      echo "  Skipping: GitHub CLI (gh) not found."
    fi
    echo "\n💉 Updating antidote plugins..."
    if command -v antidote &> /dev/null; then
      antidote update
    else
      echo "  Skipping: antidote not found."
    fi
    echo "\n🐍 Updating volta tools..."
    if command -v volta &> /dev/null; then
        volta list --format plain | while IFS= read -r line; do
            if [[ $line =~ ^runtime ]]; then
                # Handle runtime (node)
                echo "Updating node to LTS..."
                volta install node@lts
            elif [[ $line =~ ^package-manager ]]; then
                # Handle package managers
                tool=$(echo "$line" | awk '{print $2}' | sed 's/@[^/]*$//')
                echo "Updating $tool..."
                volta install "$tool@latest"
            elif [[ $line =~ ^package ]]; then
                # Handle global packages
                package=$(echo "$line" | awk '{print $2}' | sed 's/@[^/]*$//')
                [[ -n "$package" ]] || { echo "Error: empty package name from line: $line"; exit 1; }
                echo "Updating $package..."
                volta install "$package@latest"
            fi
        done
    else
      echo "  Skipping: volta not found."
    fi
    echo "\nUpdating Neovim plugins and external deps (lsps, formatters, linters, daps)..."
    if command -v nvim &> /dev/null; then
        nvim --headless -c "lua vim.pack.update({}, {force=true})" -c "qall"
        nvim --headless -c "MasonUpdate" -c "qall"
    else
      echo "  Skipping: Neovim (nvim) not found."
    fi
    echo "\n🤖 Updating Claude Code plugins..."
    if command -v claude &> /dev/null; then
        local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
        if [[ -f "$plugins_file" ]]; then
            local updated=0
            local failed=0
            local total=0

            # Extract plugin identifiers from JSON keys
            local plugin_ids=$(jq -r '.plugins | keys[]' "$plugins_file" 2>/dev/null)

            if [[ -n "$plugin_ids" ]]; then
                while IFS= read -r plugin_id; do
                    ((total++))
                    echo "  Updating $plugin_id..."
                    if claude plugin install "$plugin_id" &>/dev/null; then
                        ((updated++))
                    else
                        echo "    ⚠️  Failed to update $plugin_id"
                        ((failed++))
                    fi
                done <<< "$plugin_ids"

                echo "  Summary: $updated/$total plugins updated successfully"
                [[ $failed -gt 0 ]] && echo "  ⚠️  $failed plugin(s) failed to update"
            else
                echo "  No plugins found or failed to parse JSON"
            fi
        else
            echo "  Skipping: plugins file not found at $plugins_file"
        fi
    else
        echo "  Skipping: Claude Code (claude) not found."
    fi
    echo "======================================================================"
    echo "Finished packages update at: $(date -u +"%Y-%m-%dT%H:%M:%SZ") (UTC)"
    echo "======================================================================"
  } 2>&1 | tee -a "$LOG_FILE"
  # Update timestamp after successful completion
  echo "$(date +%s)" > "$timestamp_file"
  # Final confirmation message (this part is not logged)
  echo "✅ Packages update complete. Full log appended to: $LOG_FILE"
}

# Cleanup cache
function cleanup-cache() {
    echo -n "This will cleanup cache older than 6 months. Are you sure? [y/N] "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            find ~/.cache/ -depth -type f -atime +182 -delete
            ;;
    esac
}

# Cleanup DS_Store files
function cleanup-ds-store() {
  fd -IH .DS_Store -x rm -f {}
}

# Empty macOS Trash using Finder
function trash-empty() {
    echo -n "Empty Trash? [y/N] "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            osascript -e 'tell app "Finder" to empty'
            ;;
    esac
}
