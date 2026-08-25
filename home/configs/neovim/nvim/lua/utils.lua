local M = {}

-- Run a shell command synchronously, notifying on failure
---@param cmd string[] command and arguments
---@param opts? { namespace?: string, allow_empty?: boolean, cwd?: string }
---@return string|nil stdout (trimmed), nil on failure
M.run_cmd = function(cmd, opts)
	opts = opts or {}
	local namespace = opts.namespace or cmd[1]
	local cmd_str = table.concat(cmd, " ")

	local result = vim.system(cmd, { text = true, cwd = opts.cwd }):wait()
	if result.code ~= 0 then
		local err = (result.stderr and vim.trim(result.stderr)) or "Unknown error"
		vim.notify(namespace .. ": `" .. cmd_str .. "` failed: " .. err, vim.log.levels.WARN)
		return nil
	end

	local out = result.stdout
	if (out and vim.trim(out) == "") and not opts.allow_empty then
		vim.notify(namespace .. ": `" .. cmd_str .. "` returned empty", vim.log.levels.WARN)
		return nil
	end

	return out
end

-- Disable hard wrap and move within soft wrapped lines with j and k
M.disable_hard_wrap_for_buffer = function()
	vim.opt_local.linebreak = true
	vim.opt_local.textwidth = 0
	vim.keymap.set("n", "j", "gj", { buffer = true })
	vim.keymap.set("n", "k", "gk", { buffer = true })
end

-- Get current directory, falling back cwd when current directory is not available
M.get_current_directory = function()
	local current_file = vim.fn.expand("%:p")
	if current_file == "" then
		return vim.fn.getcwd()
	end
	return vim.fn.fnamemodify(current_file, ":h")
end

-- Get closest ancestor directory that has the given file, falling back to cwd.
---@param filename string the file to look for
M.get_closest_ancestor_directory_that_has_file = function(filename)
	return vim.fs.root(0, filename) or vim.fn.getcwd()
end

-- Override gra (code action) to show spell actions when cursor is on a misspelled word,
-- falling through to LSP code actions otherwise.
M.setup_spell_code_actions = function()
	vim.keymap.set("n", "gra", function()
		if vim.wo.spell then
			local word = vim.fn.expand("<cword>")
			local bad = vim.fn.spellbadword(word)
			if bad[1] ~= "" then
				local actions = {}

				table.insert(actions, {
					label = "Add '" .. word .. "' to spellfile",
					fn = function()
						vim.cmd("normal! zg")
					end,
				})

				table.insert(actions, {
					label = "Mark '" .. word .. "' as wrong",
					fn = function()
						vim.cmd("normal! zw")
					end,
				})

				for i, s in ipairs(vim.fn.spellsuggest(word, 5)) do
					table.insert(actions, {
						label = word .. " → " .. s,
						fn = function()
							vim.cmd("normal! " .. i .. "z=")
						end,
					})
				end

				vim.ui.select(actions, {
					prompt = "Spelling: " .. word,
					format_item = function(item)
						return item.label
					end,
				}, function(choice)
					if choice then
						choice.fn()
					end
				end)
				return
			end
		end

		vim.lsp.buf.code_action()
	end, { buffer = true, desc = "Code actions (with spelling)" })
end

-- Setup buffer for prose editing (soft wrap, spelling code actions, markdown link surround)
M.setup_prose_buffer = function()
	M.disable_hard_wrap_for_buffer()
	vim.opt_local.wrap = true -- enable soft wrap
	M.setup_spell_code_actions()
	vim.b.minisurround_config = {
		custom_surroundings = {
			-- Markdown link: saiwL, sdL, srLL
			L = {
				input = { "%[().-()%]%(.-%)" },
				output = function()
					local link = require("mini.surround").user_input("Link: ")
					return { left = "[", right = "](" .. link .. ")" }
				end,
			},
		},
	}
end

return M
