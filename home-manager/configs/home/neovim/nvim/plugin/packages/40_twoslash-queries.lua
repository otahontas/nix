require("utils").add_package({ "https://github.com/marilari88/twoslash-queries.nvim", },
  function()
    local augroup = vim.api.nvim_create_augroup("twoslash_queries_attach",
      { clear = true, })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = augroup,
      callback = function(event)
        local bufnr = event.buf

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client or client.name ~= "ts_ls" then
          return
        end

        require("twoslash-queries").attach(client, bufnr)
      end,
      pattern = { "*.ts", "*.tsx", },
    })
  end)
