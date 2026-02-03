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
