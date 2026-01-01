# === Load modular configs ===
for config in ${ZDOTDIR}/conf.d/*.zsh(N); do
  source "$config"
done
