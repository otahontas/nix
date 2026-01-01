# Rust integration

# Note: RUSTUP_HOME, CARGO_HOME are set in 22_env-base.zsh
# Note: PATH for rustup is set in 21_path.zsh

# Add cargo completions from rustc sysroot
if command -v rustc >/dev/null 2>&1; then
    fpath+=("$(rustc --print sysroot)/share/zsh/site-functions")
fi
