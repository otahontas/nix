if test -z "$TODO_FILE_LOCATION"
    echo "Error: TODO_FILE_LOCATION environment variable not set" >&2
    return 1
end

echo "$TODO_FILE_LOCATION"
