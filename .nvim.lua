local info = debug.getinfo(1, "S")
if not info then
	error("Failed to resolve .nvim.lua source")
end

local repoRoot = vim.fn.fnamemodify(info.source:sub(2), ":p:h")

vim.opt.runtimepath:append(repoRoot .. "/.nvim")

require("local_lint")
require("local_lsp")
