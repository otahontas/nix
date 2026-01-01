# Node.js package manager script runners with fzf

function _run_packagejson_script() {
    local package_manager="$1"
    if [ ! -f package.json ]; then
        echo "package.json not found" >&2
    else
        local command=$(jq '.scripts | keys[]' package.json -r | tr -d '"' |
        fzf --reverse \
            --preview-window=:wrap \
            --preview "jq '.scripts.\"{}\"' package.json -r | tr -d '\"' | sed 's/^[[:blank:]]*//'")
        if [ -n "$command" ]; then
            eval "$package_manager run $command"
        fi
    fi
}

function yarns() { _run_packagejson_script "yarn"; }
function npms() { _run_packagejson_script "npm"; }
function pnpms() { _run_packagejson_script "pnpm"; }
