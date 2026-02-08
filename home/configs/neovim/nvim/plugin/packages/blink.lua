require("blink.cmp").setup({
	enabled = function()
		return vim.bo.filetype ~= "pass"
	end,
	completion = { documentation = { auto_show = true } },
	signature = { enabled = true },
})
