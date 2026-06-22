local source = debug.getinfo(1, "S").source:sub(2)
local repoRoot = vim.env.DEVENV_ROOT

if not repoRoot or repoRoot == "" then
	repoRoot = vim.fn.fnamemodify(source, ":p:h")
end

local homeFlake = repoRoot .. "/home"

vim.lsp.config("nixd", {
	settings = {
		nixd = {
			options = {
				["home-manager"] = {
					expr = string.format('(builtins.getFlake "%s").homeConfigurations."otahontas".options', homeFlake),
				},
			},
		},
	},
})

vim.lsp.config("yamlls", {
	filetypes = {
		"yaml",
		"yaml.docker-compose",
		"yaml.github-action",
		"yaml.gitlab",
		"yaml.helm-values",
	},
})

vim.lsp.enable("nixd")
vim.lsp.enable("bashls")
vim.lsp.enable("fish_lsp")
vim.lsp.enable("jsonls")
vim.lsp.enable("lua_ls")
vim.lsp.enable("yamlls")
vim.lsp.enable("taplo")
