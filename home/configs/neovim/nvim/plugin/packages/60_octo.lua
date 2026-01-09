require("octo").setup({
	picker = "fzf-lua",
	file_panel = {
		use_icons = true,
	},
	ui = {
		use_signcolumn = true, -- show "modified" marks on the sign column
		use_signstatus = true, -- show "modified" marks on the status column
	},
	mappings = {
		submit_win = {
			-- override the default submit mapping to use Alt instead of Ctrl
			-- (ctrl is already used by wezterm for ctrl-a & ctlr-m)
			approve_review = { lhs = "<M-a>", desc = "approve review", mode = { "n", "i" } },
			comment_review = { lhs = "<M-m>", desc = "comment review", mode = { "n", "i" } },
			request_changes = { lhs = "<M-r>", desc = "request changes review", mode = { "n", "i" } },
		},
	},
})
-- parse markdown in octo buffers
vim.treesitter.language.register("markdown", "octo")
