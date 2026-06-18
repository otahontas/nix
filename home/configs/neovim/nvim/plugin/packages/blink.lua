require("blink.cmp").setup({
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
		default = { "lsp", "path", "snippets", "buffer", "copilot" },
		providers = {
			copilot = {
				name = "copilot",
				module = "blink-copilot",
				score_offset = 100,
				async = true,
				opts = {
					max_completions = 1,
					max_attempts = 4,
					debounce = 200,
					kind_icon = " ",
					auto_refresh = {
						backward = true,
						forward = true,
					},
				},
			},
		},
	},
})
