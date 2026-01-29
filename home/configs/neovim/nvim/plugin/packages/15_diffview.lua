-- Diffview setup for code review workflow
local diffview = require("diffview")

diffview.setup({
	enhanced_diff_hl = true,
	use_icons = true,
	view = {
		default = {
			layout = "diff2_horizontal",
		},
		merge_tool = {
			layout = "diff3_horizontal",
		},
	},
	file_panel = {
		listing_style = "tree",
		win_config = {
			position = "left",
			width = 35,
		},
	},
})

-- Keymaps for diffview
local set = vim.keymap.set
set("n", "<leader>dvo", "<cmd>DiffviewOpen<cr>", { desc = "Diffview: open (unstaged changes)" })
set("n", "<leader>dvm", function()
	-- Compare current branch to main/master
	local default_branch = vim.fn
		.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'")
		:gsub("%s+", "")
	if default_branch == "" then
		default_branch = "main"
	end
	vim.cmd("DiffviewOpen " .. default_branch .. "...HEAD")
end, { desc = "Diffview: compare to default branch" })
set("n", "<leader>dvh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview: file history (current file)" })
set("n", "<leader>dvH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview: file history (all)" })
set("n", "<leader>dvc", "<cmd>DiffviewClose<cr>", { desc = "Diffview: close" })
