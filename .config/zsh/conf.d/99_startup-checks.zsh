# Interactive shell startup checks

# Only run for interactive shells
if [[ -o interactive ]]; then
    _prompt_update_packages
    _prompt_homebrew_bash
fi
