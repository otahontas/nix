local lint = require("lint")

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

lint.linters_by_ft = {
	fish = { "fish" },
	markdown = { "markdownlint_file" },
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	callback = function()
		require("lint").try_lint()
	end,
})
