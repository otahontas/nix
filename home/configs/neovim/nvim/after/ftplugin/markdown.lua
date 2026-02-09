require("utils").setup_prose_buffer()

local function toggle_checkbox()
	local line = vim.api.nvim_get_current_line()
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

	if new_line ~= line then
		vim.api.nvim_set_current_line(new_line)
	end
end

vim.keymap.set("n", "<leader>xx", toggle_checkbox, { buffer = true, desc = "Toggle markdown checkbox" })
