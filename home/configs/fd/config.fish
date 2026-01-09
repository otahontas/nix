function find-and-prune --argument pattern --description "Find and delete files/directories matching pattern"
    if test -z "$pattern"
        echo "Usage: find-and-prune <pattern>"
        return 1
    end

    echo "This will delete all files/directories matching: $pattern"
    read -P "Are you sure? [y/N] " response

    switch (string lower "$response")
        case y yes
            fd -H $pattern --exec rm -rf
        case '*'
            echo Cancelled
    end
end
