$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
$env.CARAPACE_MATCH = '1'
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
mkdir ($nu.cache-dir)
source $"($nu.cache-dir)/carapace.nu"
