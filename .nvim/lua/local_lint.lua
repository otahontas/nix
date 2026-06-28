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
	-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Nix diagnostics]]
	nix = { "statix" },
})
