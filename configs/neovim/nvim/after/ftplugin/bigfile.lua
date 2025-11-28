-- Disable heavy features for large files
local buf = vim.api.nvim_get_current_buf()

-- Disable LSP
vim.schedule(function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, })) do
    vim.lsp.buf_detach_client(buf, client.id)
  end
end)

-- Disable treesitter
vim.b.ts_highlight = false
if vim.treesitter.highlighter.active[buf] then
  vim.treesitter.stop(buf)
end

-- Disable syntax highlighting
vim.opt_local.syntax = "off"

-- Disable completion
vim.b.cmp_enabled = false

-- Disable mini.nvim plugins
vim.b.minipairs_disable = true
vim.b.miniindentscope_disable = true
vim.b.minidiff_disable = true

-- Disable expensive options
vim.opt_local.swapfile = false
vim.opt_local.foldmethod = "manual"
vim.opt_local.foldenable = false
vim.opt_local.foldcolumn = "0"
vim.opt_local.undolevels = -1
vim.opt_local.undoreload = 0
vim.opt_local.list = false
vim.opt_local.spell = false
vim.opt_local.cursorline = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
