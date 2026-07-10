---@type any
local config = {
	enabled = function()
		return vim.bo.filetype ~= "pass"
	end,
	completion = {
		documentation = { auto_show = true },
		ghost_text = {
			enabled = false,
		},
	},
	signature = { enabled = true },
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
}

require("blink.cmp").setup(config)
