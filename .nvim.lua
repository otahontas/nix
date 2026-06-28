local info = debug.getinfo(1, "S")
---@cast info -nil
local repoRoot = vim.fn.fnamemodify(info.source:sub(2), ":p:h")

vim.opt.runtimepath:append(repoRoot .. "/.nvim")

require("local_lint")
require("local_lsp")
