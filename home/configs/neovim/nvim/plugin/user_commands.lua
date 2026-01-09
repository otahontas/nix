-- Helper function to open a file in a floating window
local function open_in_float(file_path)
	-- Check if buffer for this file already exists
	local existing_buf = vim.fn.bufnr(file_path)
	local buf

	if existing_buf ~= -1 then
		-- Use existing buffer
		buf = existing_buf
	else
		-- Create new buffer and load the file
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, file_path)
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("edit! " .. vim.fn.fnameescape(file_path))
		end)
	end

	-- Calculate window dimensions (80% of editor size)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)

	-- Calculate position to center the window
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Window configuration
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	}

	-- Open the floating window
	vim.api.nvim_open_win(buf, true, opts)
end

local utils = require("utils")

local function fish_path(fn_name)
	local out = utils.run_cmd({ "fish", "-lc", fn_name }, { namespace = "fish" })
	return out and vim.trim(out) or nil
end

-- Open todo.txt in a floating window (path comes from fish)
vim.api.nvim_create_user_command("Todo", function()
	local path = fish_path("todo_path")
	if not path then
		return
	end
	open_in_float(path)
end, { desc = "Open todo in floating window" })

-- Open daily note in a floating window (fish creates it if needed)
vim.api.nvim_create_user_command("Daily", function()
	local path = fish_path("daily_path")
	if not path then
		return
	end
	open_in_float(path)
end, { desc = "Open daily note in floating window" })
