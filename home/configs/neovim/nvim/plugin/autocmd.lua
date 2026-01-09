local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("TermOpen", {
	callback = function()
		vim.opt_local.spell = false
	end,
	desc = "Disable spelling in terminal",
	group = augroup("DisableSpellingInTerminal", {}),
	pattern = "*",
})

-- Disable auto-wrapping comments and disable inserting comment string after hitting 'o'.
-- Do this always on filetype to override settings from plugins
autocmd("FileType", {
	callback = function()
		vim.cmd("setlocal formatoptions-=c formatoptions-=o")
	end,
	desc = "Proper 'formatoptions'",
	group = augroup("ProperFormatOptions", {}),
	pattern = "*",
})
