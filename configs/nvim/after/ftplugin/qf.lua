-- Delete the current entry from the quickfix list with `dd`.
vim.keymap.set("n", "dd", function()
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return
  end

  local line = vim.fn.line(".")
  table.remove(qflist, line)
  vim.fn.setqflist({}, " ", { items = qflist, })

  local new_count = #qflist

  if new_count > 0 then
    local new_line = math.min(line, new_count)
    vim.api.nvim_win_set_cursor(0, { new_line, 0, })
  end
end, {
  desc = "Delete from quickfix list",
  buffer = true,
  silent = true,
})
