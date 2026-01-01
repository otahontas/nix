-- TODO: replace with:
-- https://github.com/copilotlsp-nvim/copilot-lsp

require("utils").add_package({ "https://github.com/zbirenbaum/copilot.lua", },
  function()
    -- Lua match: https://www.luadocs.com/docs/functions/string/match
    local sensitive_filename_patterns = {
      "/%.env.*$",
      "/env.*$",
      "/config$",
      "/credentials$",
    }

    -- Cache for sensitive files (limited to 100 entries to prevent unbounded growth)
    local MAX_CACHE_SIZE = 100
    local sensitive_files_cache = {}
    local cache_keys = {}

    -- Setup Copilot first time InsertEnter is triggered
    vim.api.nvim_create_autocmd("InsertEnter", {
      callback = function()
        require("copilot").setup({
          -- Do not attach to sensitive files
          should_attach = function(_, bufname)
            if sensitive_files_cache[bufname] then
              return false
            end
            for _, pattern in ipairs(sensitive_filename_patterns) do
              if string.match(bufname, pattern) then
                vim.notify("Copilot disabled for sensitive file: " .. bufname,
                  vim.log.levels.INFO)

                -- Add to cache with size limit
                if #cache_keys >= MAX_CACHE_SIZE then
                  local oldest = table.remove(cache_keys, 1)
                  sensitive_files_cache[oldest] = nil
                end
                table.insert(cache_keys, bufname)
                sensitive_files_cache[bufname] = true

                return false
              end
            end

            return true
          end,
          filetypes = {
            yazi = false,
          },
          -- Copilot requires Node.js 22+, using custom wrapper script
          copilot_node_command = "node25",
          suggestion = {
            auto_trigger = true, -- always emit suggestions
          },
          server = {
            type = "binary",
          },
          panel = {
            enabled = false,
          },
          nes = {
            enabled = false,
          },
        })
      end,
      group = vim.api.nvim_create_augroup("SetupCopilotOnInsertEnter", {}),
      desc = "Setup Copilot on InsertEnter",
      once = true,
      pattern = "*",
    })
  end
)
