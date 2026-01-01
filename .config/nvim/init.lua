-- Enable the experimental Lua module loader
vim.loader.enable()

-- === Config structure ===
-- Load order (numeric prefixes control execution):
-- 10_* → Core settings (options, no dependencies)
-- 20_* → Keymaps and simple plugins
-- 30_* → Complex plugins/autocmds requiring options/keymaps
-- 40_* → Optional/heavy plugins (copilot, etc.)
-- 50_* → Syntax/highlighting (treesitter)
--
-- Rest of the setup is read from runtime folders automatically:
-- - /plugin -> defaults
-- - /plugin/packages -> 3rd party packages
-- - /after -> personal overrides per filetype / lsp
--
-- Following is not loaded automatically by nvim itself, but is used by config:
-- /lua -> utils and tools (treesitters, lsps, formatters, linters, daps) per filetype
