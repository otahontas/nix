local socket_path = "/tmp/pi.sock"

local function send_payload(payload)
	if vim.fn.executable("nc") ~= 1 then
		vim.notify("nc not found in PATH", vim.log.levels.ERROR)
		return
	end

	local json = vim.fn.json_encode(payload) .. "\n"
	local chan = vim.fn.jobstart({ "nc", "-U", socket_path }, { stdin = "pipe" })
	if chan <= 0 then
		vim.notify("pi socket not available", vim.log.levels.ERROR)
		return
	end

	vim.fn.chansend(chan, json)
	vim.fn.chanclose(chan, "stdin")
end

local function normalize_range(start_row, start_col, end_row, end_col)
	if start_row > end_row or (start_row == end_row and start_col > end_col) then
		return end_row, end_col, start_row, start_col
	end
	return start_row, start_col, end_row, end_col
end

local function get_visual_selection()
	local bufnr = 0
	local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
	local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))

	if start_row == 0 or end_row == 0 then
		return nil
	end

	start_row, start_col, end_row, end_col = normalize_range(start_row, start_col, end_row, end_col)

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)
	if #lines == 0 then
		return nil
	end

	lines[1] = string.sub(lines[1], start_col + 1)
	lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)

	return table.concat(lines, "\n"), start_row, end_row
end

local function get_diagnostics(start_row, end_row)
	local bufnr = 0
	local result = {}

	for _, d in ipairs(vim.diagnostic.get(bufnr)) do
		local line = d.lnum + 1
		if (not start_row or line >= start_row) and (not end_row or line <= end_row) then
			local source = d.source or "lsp"
			local entry = string.format("%d:%d %s (%s)", line, d.col + 1, d.message, source)
			table.insert(result, entry)
		end
	end

	return result
end

vim.api.nvim_create_user_command("PiSelection", function()
	local selection, start_row, end_row = get_visual_selection()
	if not selection then
		vim.notify("No selection", vim.log.levels.WARN)
		return
	end

	local task = vim.fn.input("Task: ")
	local file = vim.api.nvim_buf_get_name(0)

	send_payload({
		file = file,
		range = { start_row, end_row },
		selection = selection,
		lsp = { diagnostics = get_diagnostics(start_row, end_row) },
		task = task,
	})
end, { desc = "Send selection to pi" })

vim.api.nvim_create_user_command("PiCursor", function()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local file = vim.api.nvim_buf_get_name(0)
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	local task = vim.fn.input("Task: ")

	send_payload({
		file = file,
		range = { row, row },
		selection = line,
		lsp = { diagnostics = get_diagnostics(row, row) },
		task = task,
	})
end, { desc = "Send cursor line to pi" })

vim.keymap.set("v", "<leader>ps", "<cmd>PiSelection<cr>", { silent = true, desc = "Pi: send selection" })
vim.keymap.set("n", "<leader>pc", "<cmd>PiCursor<cr>", { silent = true, desc = "Pi: send cursor line" })
