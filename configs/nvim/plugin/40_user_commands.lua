-- Add command for running pack.update
vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update({})
end, { desc = "Update all plugins", })
