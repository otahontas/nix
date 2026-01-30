-- Language configurations per filetype
-- Loaded by different plugins (e.g., treesitter, lspconfig)
local languages = {
	bash = {
		treesitter = "bash",
		lsp = { "bashls" },
	},
	c = { treesitter = "c" },
	dockerfile = { treesitter = "dockerfile" },
	gitcommit = { treesitter = "gitcommit" },
	gitignore = { treesitter = "gitignore" },
	go = { treesitter = "go" },
	gomod = { treesitter = "gomod" },
	help = { treesitter = "vimdoc" },
	html = { treesitter = "html" },
	javascript = {
		treesitter = "javascript",
		lsp = { "ts_ls", "eslint" },
	},
	javascriptreact = {
		treesitter = "javascript",
		lsp = { "ts_ls", "eslint" },
	},
	json = {
		treesitter = "json",
		lsp = { "jsonls", "eslint" },
		formatter = "jsonls",
	},
	lua = {
		treesitter = "lua",
		lsp = { "emmylua_ls" },
		formatter = "emmylua_ls",
	},
	make = { treesitter = "make" },
	markdown = {
		treesitter = "markdown",
	},
	matlab = { treesitter = "matlab" },
	nix = {
		treesitter = "nix",
		lsp = { "nixd" },
		formatter = "nixd",
	},
	nu = {
		treesitter = "nu",
		lsp = { "nushell", "efm" },
		formatter = "efm",
	},
	python = {
		treesitter = "python",
		lsp = { "basedpyright", "ruff" },
		formatter = "ruff",
	},
	sql = {
		treesitter = "sql",
		lsp = { "postgres_lsp" },
	},
	sshconfig = { treesitter = "ssh_config" },
	tex = { treesitter = "latex" },
	todotxt = { treesitter = "todotxt" },
	toml = { treesitter = "toml" },
	typescript = {
		treesitter = "typescript",
		lsp = { "ts_ls", "eslint" },
	},
	typescriptreact = {
		treesitter = "tsx",
		lsp = { "ts_ls", "eslint" },
	},
	typst = { treesitter = "typst" },
	vim = { treesitter = "vim" },
	yaml = {
		treesitter = "yaml",
	},
}

-- Module exports
local M = {}
M.lsps = {}
M.formatters = {}

vim.iter(languages):each(function(filetype, config)
	vim.list_extend(M.lsps, config.lsp or {})
	if config.formatter then
		M.formatters[filetype] = config.formatter
	end
end)

table.sort(M.lsps)

return M
