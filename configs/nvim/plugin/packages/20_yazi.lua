require("utils").add_package({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/mikavilpas/yazi.nvim",
}, function()
  -- disable netrw
  vim.g.loaded_netrwPlugin = 1
  vim.g.loaded_netrw = 1

  -- load yazi & set keymaps
  require("yazi").setup({
    open_for_directories = true,
  })
  vim.keymap.set("n", "<leader>ee", "<cmd>Yazi<cr>",
    { desc = "Open yazi at the current file", })
  vim.keymap.set("n", "<leader>en", "<cmd>Yazi cwd<cr>",
    { desc = "Open the file manager in nvim's working directory", })
end)
