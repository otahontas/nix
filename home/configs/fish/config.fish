# enable vi mode
fish_vi_key_bindings

# clear screen + scrollback at startup (hides "Last login" after the fact)
set -g fish_greeting
printf '\33c\e[3J'

# List listening TCP ports, optionally filter by pattern
function listening
    if test -n "$argv[1]"
        lsof -iTCP -sTCP:LISTEN -n -P | grep -i "$argv[1]"
    else
        lsof -iTCP -sTCP:LISTEN -n -P
    end
end

# Kill all processes on a given port
function nukeport
    if test -z "$argv[1]"
        echo "Usage: nukeport <port>"
        return 1
    end

    set -l pids (lsof -ti :$argv[1] | sort -u)

    if test -z "$pids"
        echo "No process found on port $argv[1]"
        return
    end

    for pid in $pids
        echo "Killing PID $pid on port $argv[1]"
        kill -9 $pid
    end

    echo "✓ Port $argv[1] freed"
end

# Empty trash with confirmation
function trash-empty
    read -P "Empty Trash? [y/N] " response
    switch (string lower $response)
        case y yes
            if osascript -e 'tell application "Finder" to empty trash' 2>/dev/null
                echo "✓ Trash emptied"
            else
                echo "✗ Failed to empty trash"
                return 1
            end
        case '*'
            echo Cancelled
    end
end

# Fish completion for `devenv tasks run <task>`
function __fish_devenv_list_tasks
    type -q devenv; or return 0
    devenv tasks list 2>/dev/null | string replace -r '^.*── ' ''
end

function __fish_devenv_should_complete_tasks
    __fish_seen_subcommand_from tasks; or return 1
    __fish_seen_subcommand_from run; or return 1

    set -l token (commandline -ct)
    string match -qr '^-' -- $token; and return 1

    __fish_prev_arg_in \
        --mode -m \
        --log-format \
        --trace-export-file \
        --max-jobs -j \
        --cores -u \
        --system -s \
        --clean -c \
        --nix-option -n \
        --override-input -o \
        --option -O \
        --profile -P
    and return 1

    return 0
end

complete -c devenv -n __fish_devenv_should_complete_tasks -f -a '(__fish_devenv_list_tasks)' -d Task
