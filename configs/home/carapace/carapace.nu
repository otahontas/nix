$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
$env.CARAPACE_MATCH = '1'
mkdir ($nu.cache-dir)
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
source $"($nu.cache-dir)/carapace.nu"
