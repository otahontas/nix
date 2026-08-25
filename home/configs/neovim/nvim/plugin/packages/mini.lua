-- Setup mini modules

-- with default settings
require("mini.git").setup()
require("mini.notify").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()
require("mini.surround").setup()

-- with non-default settings
require("mini.diff").setup({
	-- use signs always
	view = {
		style = "sign",
		signs = { add = "▒", change = "▒", delete = "▒" },
	},
	options = {
		algorithm = "patience",
		wrap_goto = true,
	},
})
require("mini.indentscope").setup({
	draw = {
		-- Skip animation
		animation = require("mini.indentscope").gen_animation.none(),
	},
})
local miniMap = require("mini.map")
miniMap.setup({
	integrations = {
		miniMap.gen_integration.builtin_search(),
		miniMap.gen_integration.diff(),
		miniMap.gen_integration.diagnostic(),
	},
})
vim.keymap.set("n", "<Leader>mmt", miniMap.toggle)
vim.keymap.set("n", "<Leader>mmf", miniMap.toggle_focus)

-- Open diff overlay
vim.keymap.set("n", "<Leader>do", "<Cmd>lua MiniDiff.toggle_overlay()<CR>", { desc = "Toggle mini diff overlay" })

-- setup and mock exported functions of 'nvim-tree/nvim-web-devicons'
local miniIcons = require("mini.icons")
miniIcons.setup()
miniIcons.mock_nvim_web_devicons()

-- show notification history for mini
vim.keymap.set("n", "<Leader>mnsh", "<Cmd>lua MiniNotify.show_history()<CR>", { desc = "Show notification history" })

-- navigate to git info at cursor
local show_at_cursor = "<Cmd>lua MiniGit.show_at_cursor()<CR>"
vim.keymap.set({ "n", "x" }, "<Leader>gs", show_at_cursor, { desc = "Show at cursor" })

-- fast blame
local git_blame = "<Cmd>vert Git blame -- %<CR>"
vim.keymap.set({ "n", "x" }, "<Leader>gb", git_blame, { desc = "Show at cursor" })
