function lefthook-setup
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null | string trim)
    if test -z "$repo_root"
        echo "Error: Not in a git repository"
        return 1
    end

    set -l template "$HOME/.config/git/lefthook.yml"

    if not test -e "$template"
        echo "Error: Template not found: $template"
        return 1
    end

    set -l lefthook_file "$repo_root/lefthook.yml"

    if test -e "$lefthook_file"
        read -l -P "lefthook.yml already exists. Overwrite? [y/N] " response
        if not string match -qi -r '^(y|yes)$' -- "$response"
            echo Cancelled
            return 0
        end
        rm -f "$lefthook_file"
    end

    cp -L "$template" "$lefthook_file"
    echo "📝 Created lefthook.yml"

    lefthook install
    echo "✅ Lefthook installed in $repo_root"
end
