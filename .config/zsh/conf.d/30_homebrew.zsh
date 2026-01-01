# Homebrew integration

# Wrapper function to auto-dump Brewfile on certain commands
function brew() {
    local dump_commands=("install" "uninstall" "tap" "untap" "upgrade" "update")
    local main_command="${1}"
    local brewfile_path="$XDG_DATA_HOME/brew/brewfile"

    /opt/homebrew/bin/brew ${@}
    local brew_exit=$?

    if [[ $brew_exit -eq 0 ]]; then
        for command in "${dump_commands[@]}"; do
            [[ "${command}" == "${main_command}" ]] && \
                /opt/homebrew/bin/brew bundle dump --file="$brewfile_path" --force
        done
    fi

    return $brew_exit
}
