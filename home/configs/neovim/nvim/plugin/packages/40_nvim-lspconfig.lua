-- Add the same capabilities to ALL server configurations.
-- Refer to :h vim.lsp.config() for more information.
vim.lsp.config("*", {
	capabilities = vim.lsp.protocol.make_client_capabilities(),
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("EnableFeaturesBasedOnClientCapabilities", {}),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local bufnr = args.buf

		if not client then
			vim.notify("LspAttach was fired, but there was no client", vim.log.levels.WARN)
			return
		end

		-- Setup inlay hints toggle if server supports them
		if client.server_capabilities and client.server_capabilities.inlayHintProvider then
			-- Enable inlay hints by default for this buffer
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			-- Create a keymap to toggle inlay hints
			vim.keymap.set("n", "<leader>tih", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
			end, { buffer = bufnr, desc = "Toggle inlay hints" })
		end

		-- Setup folding based on LSP if supported
		if client:supports_method("textDocument/foldingRange") then
			local win = vim.api.nvim_get_current_win()
			vim.wo.foldmethod = "expr"
			vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
		end
	end,
})
