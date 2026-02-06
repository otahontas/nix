require("markview").setup({
	preview = {
		icon_provider = "mini",
	},
})
vim.api.nvim_set_keymap("n", "<leader>mw", "<cmd>Markview<cr>", { desc = "Toggle `markview` globally" })
