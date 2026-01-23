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

autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ timeout = 200, visual = true })
	end,
	desc = "Highlight selection on yank",
	group = augroup("HighlightYank", { clear = true }),
	pattern = "*",
})

autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
	desc = "Restore cursor to file position in previous editing session",
	group = augroup("RestoreCursor", { clear = true }),
})

autocmd("FileType", {
	command = "wincmd L",
	desc = "Open help in vertical split",
	pattern = "help",
})

autocmd("VimResized", {
	command = "wincmd =",
	desc = "Auto resize splits when terminal window is resized",
})

autocmd({ "WinEnter", "BufEnter" }, {
	callback = function()
		vim.opt_local.cursorline = true
	end,
	desc = "Show cursorline in active window",
	group = augroup("ActiveCursorline", { clear = true }),
})

autocmd({ "WinLeave", "BufLeave" }, {
	callback = function()
		vim.opt_local.cursorline = false
	end,
	desc = "Hide cursorline in inactive window",
	group = "ActiveCursorline",
})

autocmd("CursorMoved", {
	callback = function()
		if vim.fn.mode() ~= "i" then
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			local supports_highlight = false
			for _, client in ipairs(clients) do
				if client.server_capabilities.documentHighlightProvider then
					supports_highlight = true
					break
				end
			end
			if supports_highlight then
				vim.lsp.buf.clear_references()
				vim.lsp.buf.document_highlight()
			end
		end
	end,
	desc = "Highlight references under cursor",
	group = augroup("LspReferenceHighlight", { clear = true }),
})

autocmd("CursorMovedI", {
	callback = function()
		vim.lsp.buf.clear_references()
	end,
	desc = "Clear highlights when entering insert mode",
	group = "LspReferenceHighlight",
})
