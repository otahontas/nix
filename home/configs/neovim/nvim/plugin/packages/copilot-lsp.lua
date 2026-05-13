-- Copilot Language Server configuration
-- Auth: :LspCopilotSignIn (per buffer, copilot must be attached)

local function sign_in(client, bufnr)
  client:request("signIn", vim.empty_dict(), function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end
    if result.command then
      local code = result.userCode
      vim.fn.setreg("+", code)
      vim.fn.setreg("*", code)
      local continue = vim.fn.confirm(
        "Copied one-time code to clipboard.\nOpen browser to complete sign-in?",
        "&Yes\n&No"
      )
      if continue == 1 then
        client:exec_cmd(result.command, { bufnr = bufnr }, function(cmd_err, cmd_result)
          if cmd_err then
            vim.notify(cmd_err.message, vim.log.levels.ERROR)
            return
          end
          if cmd_result.status == "OK" then
            vim.notify("Signed in as " .. cmd_result.user .. ".")
          end
        end)
      end
    end
    if result.status == "PromptUserDeviceFlow" then
      vim.notify("Enter one-time code " .. result.userCode .. " at " .. result.verificationUri)
    elseif result.status == "AlreadySignedIn" then
      vim.notify("Already signed in as " .. result.user .. ".")
    end
  end)
end

local function sign_out(client)
  client:request("signOut", vim.empty_dict(), function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end
    if result.status == "SignedIn" then
      vim.notify("Signed out.")
    end
  end)
end

vim.lsp.config("copilot", {
  cmd = { "copilot-language-server", "--stdio" },
  root_markers = { ".git" },
  init_options = {
    editorInfo = {
      name = "Neovim",
      version = tostring(vim.version()),
    },
    editorPluginInfo = {
      name = "Neovim",
      version = tostring(vim.version()),
    },
  },
  settings = {
    telemetry = {
      telemetryLevel = "all",
    },
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "copilot" then
      return
    end
    local bufnr = args.buf
    vim.api.nvim_buf_create_user_command(bufnr, "LspCopilotSignIn", function()
      sign_in(client, bufnr)
    end, { desc = "Sign in to GitHub Copilot" })
    vim.api.nvim_buf_create_user_command(bufnr, "LspCopilotSignOut", function()
      sign_out(client)
    end, { desc = "Sign out of GitHub Copilot" })
  end,
})

vim.lsp.enable("copilot")
