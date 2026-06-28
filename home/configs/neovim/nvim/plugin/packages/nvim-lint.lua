vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
	callback = function()
		require("lint").try_lint()
	end,
})
