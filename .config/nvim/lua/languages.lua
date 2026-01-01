-- Language configurations per filetype
-- Loaded by different plugins (e.g., treesitter, lspconfig)
local languages = {
  bash = {
    treesitter = "bash",
    lsp = { "bashls", },
  },
  c = { treesitter = "c", },
  dockerfile = { treesitter = "dockerfile", },
  gitcommit = { treesitter = "gitcommit", },
  gitignore = { treesitter = "gitignore", },
  go = { treesitter = "go", },
  gomod = { treesitter = "gomod", },
  help = { treesitter = "vimdoc", },
  html = { treesitter = "html", },
  javascript = {
    treesitter = "javascript",
    lsp = { "ts_ls", "eslint", },
  },
  javascriptreact = {
    treesitter = "javascript",
    lsp = { "ts_ls", "eslint", },
  },
  json = {
    treesitter = "json",
    lsp = { "jsonls", "eslint", },
    formatter = "jsonls",
  },
  lua = {
    treesitter = "lua",
    lsp = { "lua_ls", },
    formatter = "lua_ls",
  },
  make = { treesitter = "make", },
  markdown = {
    treesitter = "markdown",
  },
  matlab = { treesitter = "matlab", },
  python = {
    treesitter = "python",
    lsp = { "based_pyright", "ruff_lsp", },
    formatter = "ruff_lsp",
  },
  sql = { treesitter = "sql", },
  sshconfig = { treesitter = "ssh_config", },
  tex = { treesitter = "latex", },
  todotxt = { treesitter = "todotxt", },
  toml = { treesitter = "toml", },
  typescript = {
    treesitter = "typescript",
    lsp = { "ts_ls", "eslint", },
  },
  typescriptreact = {
    treesitter = "typescript",
    lsp = { "ts_ls", "eslint", },
  },
  typst = { treesitter = "typst", },
  vim = { treesitter = "vim", },
  yaml = {
    treesitter = "yaml",
  },
}

-- Treesitter that aren't directly tied to a specific filetype
local extra_treesitters = {
  "comment",
  "ecma",
  "gosum",
  "html_tags",
  "luadoc",
  "luap",
  "markdown_inline",
  "query",
}

-- Module exports
local M = {}
M.filetypes = vim.tbl_keys(languages)
M.treesitters = vim.list_extend({}, extra_treesitters)
M.lsps = {}
M.formatters = {}

vim.iter(languages):each(function(filetype, config)
  vim.list_extend(M.treesitters, config.treesitter and { config.treesitter, } or {})
  vim.list_extend(M.lsps, config.lsp or {})
  if config.formatter then
    M.formatters[filetype] = config.formatter
  end
end)

table.sort(M.filetypes)
table.sort(M.treesitters)
table.sort(M.lsps)

return M
