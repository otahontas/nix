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
		-- Find copilot-node-server and node in PATH
		local copilot_cmd = vim.fn.exepath("copilot-node-server")
		local node_cmd = vim.fn.exepath("node")

		if copilot_cmd == "" then
			vim.notify("copilot-node-server not found in PATH", vim.log.levels.ERROR)
			return
		end

		if node_cmd == "" then
			vim.notify("node not found in PATH", vim.log.levels.ERROR)
			return
		end

		require("copilot").setup({
			-- Do not attach to sensitive files
			should_attach = function(_, bufname)
				if sensitive_files_cache[bufname] then
					return false
				end
				for _, pattern in ipairs(sensitive_filename_patterns) do
					if string.match(bufname, pattern) then
						vim.notify("Copilot disabled for sensitive file: " .. bufname, vim.log.levels.INFO)

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

				-- attach to buffer yeah
				vim.api.nvim_create_autocmd("User", {
					pattern = "BlinkCmpMenuOpen",
					callback = function()
						vim.b.copilot_suggestion_hidden = true
					end,
				})

				vim.api.nvim_create_autocmd("User", {
					pattern = "BlinkCmpMenuClose",
					callback = function()
						vim.b.copilot_suggestion_hidden = false
					end,
				})

				return true
			end,
			filetypes = {
				yazi = false,
			},
			suggestion = {
				auto_trigger = true, -- always emit suggestions
			},
			copilot_node_command = node_cmd,
			server = {
				type = "binary",
				custom_server_filepath = copilot_cmd,
			},
			server_opts_overrides = {
				trace = "verbose",
			},
			panel = {
				enabled = false,
			},
		})
	end,
	group = vim.api.nvim_create_augroup("SetupCopilotOnInsertEnter", {}),
	desc = "Setup Copilot on InsertEnter",
	once = true,
	pattern = "*",
})
