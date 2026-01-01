# General utility functions

# Create folder and cd to it
function mcd() {
    mkdir "$1" && cd "$1"
}

# Cd to folder and list content
function cl() {
    cd "$1" && ls .
}

# Show listening ports
function listening() {
    if [ $# -eq 0 ]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    elif [ $# -eq 1 ]; then
        sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
    else
        echo "Usage: listening [pattern]"
    fi
}

# Show local IP addresses
function myip() {
    ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}'
}

# Find and remove directories/files by name
function find-and-prune() {
    if [[ -z "$1" ]]; then
        echo "Usage: find-and-prune PATTERN"
        return 1
    fi

    echo "This will delete all files/directories matching: $1"
    echo -n "Are you sure? [y/N] "
    read -r response

    case "$response" in
        [yY]|[yY][eE][sS])
            find . -name "$1" -prune -print0 | xargs -0 rm -rf
            ;;
        *)
            echo "Cancelled"
            ;;
    esac
}

# Print terminal color palette
function palette() {
    local -a colors
    for i in {000..255}; do
        colors+=("%F{$i}$i%f")
    done
    print -cP $colors
}

# Print terminal color code formatted
# Usage: print-color COLOR_CODE
function print-color() {
    local color="%F{$1}"
    echo -E ${(qqqq)${(%)color}}
}

# Combine PDFs from a folder into a single PDF
function combine-pdfs-in-folder() {
    local folder="${1:-.}"

    # Remove trailing slash if present
    folder="${folder%/}"

    # Get basename of folder
    local basename="${folder:t}"

    # Get all PDF files sorted
    local pdfs=("${folder}"/*.pdf(N))

    if [[ ${#pdfs} -eq 0 ]]; then
        echo "No PDF files found in ${folder}"
        return 1
    fi

    # Output file
    local output="${basename}.pdf"

    echo "Combining ${#pdfs} PDFs from ${folder} into ${output}..."

    pdfunite "${pdfs[@]}" "${output}"

    if [[ $? -eq 0 ]]; then
        echo "Created ${output}"
    else
        echo "Failed to create ${output}"
        return 1
    fi
}

# macOS sleep control
function disable-sleep() {
    sudo pmset -a disablesleep 1
}

function enable-sleep() {
    sudo pmset -a disablesleep 0
}

# Open today's (or the specified) daily note under ~/Documents/notes/daily
function daily() {
    local notes_dir="${HOME}/Documents/notes/daily"
    local date_str

    if [[ -n "$1" ]]; then
        if [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            date_str="$1"
        else
            echo "Usage: daily [YYYY-MM-DD]" >&2
            return 1
        fi
    else
        date_str="$(date +%Y-%m-%d)"
    fi

    local note_path="${notes_dir}/${date_str}.md"
    mkdir -p "$notes_dir"
    [[ -f "$note_path" ]] || : > "$note_path"

    local -a opener
    if [[ -n "$VISUAL" ]]; then
        opener=(${=VISUAL})
    elif [[ -n "$EDITOR" ]]; then
        opener=(${=EDITOR})
    elif command -v open >/dev/null 2>&1; then
        opener=(open)
    elif command -v xdg-open >/dev/null 2>&1; then
        opener=(xdg-open)
    else
        echo "$note_path"
        return 0
    fi

    "${opener[@]}" "$note_path"
}
