require("utils").setup_prose_buffer()

local function toggle_line(line)
	local new_line = line

	if line:match("%[ %]") then
		new_line = line:gsub("%[ %]", "[x]", 1)
	elseif line:match("%[[xX]%]") then
		new_line = line:gsub("%[[xX]%]", "[ ]", 1)
	else
		-- Add checkbox if missing
		if line:match("^%s*[-*+]%s") then
			new_line = line:gsub("^(%s*[-*+])(%s+)", "%1 [ ]%2", 1)
		elseif line:match("^%s*%d+%.%s") then
			new_line = line:gsub("^(%s*%d+%.)(%s+)", "%1 [ ]%2", 1)
		else
			local indent = line:match("^(%s*)")
			local text = line:match("^%s*(.*)") or ""
			if text == "" then
				new_line = indent .. "- [ ] "
			else
				new_line = indent .. "- [ ] " .. text
			end
		end
	end

	return new_line
end

local function toggle_checkbox_range(start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	local new_lines = {}
	local changed = false
	for i, line in ipairs(lines) do
		local new_line = toggle_line(line)
		new_lines[i] = new_line
		if new_line ~= line then
			changed = true
		end
	end
	if changed then
		vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
	end
end

local function toggle_checkbox()
	local mode = vim.fn.mode()
	local start_line, end_line

	if mode == "v" or mode == "V" or mode == "\22" then
		-- Visual mode: exit visual to set '< '> marks, then use them
		vim.cmd("normal! <Esc>")
		start_line = vim.fn.line("'<")
		end_line = vim.fn.line("'>")
	else
		start_line = vim.api.nvim_win_get_cursor(0)[1]
		end_line = start_line
	end

	toggle_checkbox_range(start_line, end_line)
end

vim.keymap.set("n", "<leader>xx", toggle_checkbox, { buffer = true, desc = "Toggle markdown checkbox" })
vim.keymap.set("x", "<leader>xx", toggle_checkbox, { buffer = true, desc = "Toggle markdown checkboxes in selection" })
