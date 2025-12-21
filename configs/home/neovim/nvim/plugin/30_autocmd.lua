local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Format on save using LSP formatter if configured (editorconfig handles whitespace trimming)
autocmd("BufWritePre", {
  callback = function()
    if vim.b.format_on_save_disable or not vim.b.format_on_save_fn then
      return
    end
    vim.b.format_on_save_fn()
  end,
  desc = "Format on save using LSP formatter",
  group = augroup("FormatOnSave", {}),
  pattern = "*",
})

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
  callback = function() vim.cmd("setlocal formatoptions-=c formatoptions-=o") end,
  desc = "Proper 'formatoptions'",
  group = augroup("ProperFormatOptions", {}),
  pattern = "*",
})

-- Run post-install tasks for packages. Packages can define a task function in their
-- spec.data.task that runs after install/update (but not delete).
autocmd("PackChanged", {
  callback = function(event)
    local event_data = event.data
    local task = (event_data.spec.data or {}).task
    if event_data.kind ~= "delete" and type(task) == "function" then
      vim.notify("Running task for package: " .. event_data.spec.name,
        vim.log.levels.INFO, { title = "Package Task", })
      pcall(task, event_data)
    end
  end,
  desc = "Run task with metadata for package if defined",
  group = augroup("RunTaskAfterPackageChanged", {}),
  pattern = "*",
})
