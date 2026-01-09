if test -z "$DAILY_FOLDER_LOCATION"
    echo "Error: DAILY_FOLDER_LOCATION environment variable not set" >&2
    return 1
end

set -l today (date "+%F")
set -l daily_file "$DAILY_FOLDER_LOCATION/$today.md"
set -l template_file "$DAILY_FOLDER_LOCATION/daily_template.txt"

if not test -e "$daily_file"
    if not test -e "$template_file"
        echo "Error: daily template not found at $template_file" >&2
        return 1
    end

    string replace -a "<YYYY-MM-DD>" "$today" <"$template_file" >"$daily_file"
end

echo "$daily_file"
