-- ESLint LSP configuration overrides
local lsp = vim.lsp

return {
  -- Override filetypes to only JS/TS files
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  -- Override root_dir to search for eslint.config.mjs
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, { "eslint.config.mjs", })
    if root then
      on_dir(root)
    else
      vim.notify("ESLint config not found in project", vim.log.levels.WARN)
    end
  end,
  -- Override on_attach to auto-format on save
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("eslint_fix_" .. bufnr, { clear = false, }),
      buffer = bufnr,
      callback = function()
        local ok, err = pcall(function()
          client:request_sync("workspace/executeCommand", {
            command = "eslint.applyAllFixes",
            arguments = {
              {
                uri = vim.uri_from_bufnr(bufnr),
                version = lsp.util.buf_versions[bufnr],
              },
            },
          }, nil, bufnr)
        end)
        if not ok then
          vim.notify("ESLint fix failed: " .. tostring(err), vim.log.levels.WARN)
        end
      end,
      desc = "ESLint fix all on save",
    })
  end,
  -- Override settings to enable flat config
  settings = {
    experimental = {
      useFlatConfig = true,
    },
  },
}
