require("utils").add_package({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
}, function()
  require("mason").setup()

  local languages = require("languages")

  -- TODO: Add automatic LSP installation (NOTE: mason registry names differ from lspconfig names)

  -- Enable all LSP servers defined in languages.lua
  vim.lsp.enable(languages.lsps)

  -- Setup auto-formatting on save for filetypes that use LSP formatters
  local function setup_format_on_save (bufnr, client_id)
    return function()
      vim.lsp.buf.format({ bufnr = bufnr, id = client_id, timeout_ms = 500, })
    end
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_autoformat", {}),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local bufnr = args.buf
      local filetype = vim.bo[bufnr].filetype
      local formatter = languages.formatters[filetype]

      if not client then
        vim.notify("LspAttach was fired, but there was no client")
        return
      end

      -- Setup inlay hints toggle if server supports them
      if client.server_capabilities.inlayHintProvider then
        -- Enable inlay hints by default for this buffer
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr, })
        -- Create a keymap to toggle inlay hints
        vim.keymap.set("n", "<leader>tih", function()
          vim.lsp.inlay_hint.enable(
            not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr, }),
            { bufnr = bufnr, })
        end, { buffer = bufnr, desc = "Toggle inlay hints", })
      end

      -- Setup auto-formatting on save if the client is marked as the formatter for this filetype
      local is_correct_formatter = formatter == client.name
      local supports_formatting = client:supports_method("textDocument/formatting")
      local needs_manual_trigger =
        not client:supports_method("textDocument/willSaveWaitUntil")

      if is_correct_formatter and supports_formatting and needs_manual_trigger then
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = vim.api.nvim_create_augroup(
            "lsp_autoformat_" .. bufnr,
            { clear = false, }
          ),
          buffer = bufnr,
          callback = setup_format_on_save(bufnr, client.id),
        })
      end

      if client:supports_method("textDocument/foldingRange") then
        local win = vim.api.nvim_get_current_win()
        vim.wo.foldmethod = "expr"
        vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      end
    end,
  })
end)
