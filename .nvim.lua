local info = debug.getinfo(1, "S")
if not info then
	error("failed to determine repo config path")
end

local source = info.source:sub(2)
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

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#JSON diagnostics]]
vim.lsp.config("jsonls", {
	cmd = { "vscode-json-languageserver", "--stdio" },
})

local lint = require("lint")

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Markdown diagnostics]]
lint.linters.markdownlint_file = vim.tbl_extend("force", lint.linters.markdownlint, {
	stdin = false,
	append_fname = true,
	args = {},
	stream = "stderr",
	parser = require("lint.parser").from_errorformat("%f:%l:%c %m,%f:%l %m", {
		source = "markdownlint",
		severity = vim.diagnostic.severity.WARN,
	}),
})

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Fish diagnostics]]
lint.linters_by_ft = vim.tbl_extend("force", lint.linters_by_ft, {
	fish = { "fish" },
	markdown = { "markdownlint_file" },
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	group = vim.api.nvim_create_augroup("nix_repo_lint", { clear = true }),
	callback = function()
		require("lint").try_lint()
	end,
})

vim.lsp.enable("nixd")
-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Bash diagnostics]]
vim.lsp.enable("bashls")
vim.lsp.enable("fish_lsp")
vim.lsp.enable("jsonls")
-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Lua diagnostics]]
vim.lsp.enable("emmylua_ls")
vim.lsp.enable("yamlls")
-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#TOML diagnostics]]
vim.lsp.enable("taplo")
