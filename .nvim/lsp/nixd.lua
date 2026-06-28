local info = debug.getinfo(1, "S")
if not info then
	error("failed to determine repo config path")
end

local source = info.source:sub(2)
local repoRoot = vim.fn.fnamemodify(source, ":p:h:h:h")
local homeFlake = repoRoot .. "/home"

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Nix diagnostics]]
return {
	settings = {
		nixd = {
			options = {
				["home-manager"] = {
					expr = string.format('(builtins.getFlake "%s").homeConfigurations."otahontas".options', homeFlake),
				},
			},
		},
	},
}
