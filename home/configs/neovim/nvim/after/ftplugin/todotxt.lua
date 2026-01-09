local utils = require("utils")
utils.setup_prose_buffer()

-- toggle done with commentstring
vim.bo.commentstring = "x %s"

-- Date patterns
local PATTERNS = {
	due = "due:(%d%d%d%d%-%d%d%-%d%d)",
	threshold = "t:(%d%d%d%d%-%d%d%-%d%d)",
	completed = "^x %d%d%d%d%-%d%d%-%d%d",
}

-- Cache today's date
local today = os.date("%Y-%m-%d")

-- Highlight overdue and active threshold dates
---@type table<string, integer>
local match_ids = {}

local function highlight_dates()
	-- Clear existing highlights
	for key, id in pairs(match_ids) do
		pcall(vim.fn.matchdelete, id)
		match_ids[key] = nil
	end

	today = os.date("%Y-%m-%d")
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local positions = { due = {}, threshold = {} }

	for lnum, line in ipairs(lines) do
		if not line:match(PATTERNS.completed) then
			for key, pattern in pairs({ due = PATTERNS.due, threshold = PATTERNS.threshold }) do
				local s, e, date = line:find(pattern)
				if date and s and e and date <= today then
					table.insert(positions[key], { lnum, s, e - s + 1 })
				end
			end
		end
	end

	local hl = { due = "ErrorMsg", threshold = "DiagnosticInfo" }
	for key, pos in pairs(positions) do
		if #pos > 0 then
			match_ids[key] = vim.fn.matchaddpos(hl[key], pos, 10) --[[@as integer]]
		end
	end
end

-- Token patterns
local TOKEN = {
	date = "^%d%d%d%d%-%d%d%-%d%d$",
	priority = "^%([A-Z]%)$",
	context = "^@%S+$",
	project = "^%+%S+$",
	key_value = "^[^%s:]+:[^%s]+$",
}

local function is_key_value(token)
	return token:match(TOKEN.key_value) and not token:match("://")
end

local TodoLine = {}
TodoLine.__index = TodoLine

function TodoLine.parse(line)
	local trimmed = vim.trim(line)
	local tokens = (trimmed == "") and {} or vim.split(trimmed, "%s+", { trimempty = true })

	local obj = {
		raw = line,
		leading = line:match("^(%s*)") or "",
		trailing = line:match("(%s*)$") or "",
		tokens = tokens,
		prefix = {},
		priority = nil,
		description = {},
		contexts = {},
		projects = {},
		meta = { due = {}, t = {}, est = {}, other = {} },
	}

	setmetatable(obj, TodoLine)

	if #tokens == 0 then
		return obj
	end

	local idx = 1
	if tokens[idx] == "x" then
		table.insert(obj.prefix, tokens[idx])
		idx = idx + 1
		while tokens[idx] and tokens[idx]:match(TOKEN.date) do
			table.insert(obj.prefix, tokens[idx])
			idx = idx + 1
		end
	end

	for i = idx, #tokens do
		local t = tokens[i] --[[@as string]]
		if not obj.priority and t:match(TOKEN.priority) then
			obj.priority = t
		elseif t:match(TOKEN.context) then
			table.insert(obj.contexts, t)
		elseif t:match(TOKEN.project) then
			table.insert(obj.projects, t)
		elseif is_key_value(t) then
			local key = t:match("^([^:]+):") --[[@as string]]
			table.insert(obj.meta[key] or obj.meta.other, t)
		else
			table.insert(obj.description, t)
		end
	end

	return obj
end

function TodoLine:get_meta_value(key)
	local bucket = self.meta[key]
	if not bucket or not bucket[1] then
		return nil
	end
	return bucket[1]:match(":(%S+)$")
end

function TodoLine:set_meta_value(key, value)
	self.meta[key] = self.meta[key] or {}
	self.meta[key][1] = key .. ":" .. value
end

function TodoLine:render()
	if #self.tokens == 0 then
		return self.raw
	end

	local r = {}
	vim.list_extend(r, self.prefix)
	if self.priority then
		r[#r + 1] = self.priority
	end
	vim.list_extend(r, self.description)
	vim.list_extend(r, self.contexts)
	vim.list_extend(r, self.projects)
	for _, key in ipairs({ "due", "t", "est", "other" }) do
		vim.list_extend(r, self.meta[key])
	end
	return self.leading .. table.concat(r, " ") .. self.trailing
end

local function format_buffer()
	local buf = 0
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local changed = false

	for idx, line in ipairs(lines) do
		local formatted = TodoLine.parse(line):render()
		if formatted ~= line then
			lines[idx] = formatted
			changed = true
		end
	end

	if changed then
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end

	highlight_dates()
end

local function adjust_meta_date(meta_key, delta)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
	if line == "" then
		return
	end

	local todo = TodoLine.parse(line)
	if #todo.tokens == 0 then
		return
	end

	local current_value = todo:get_meta_value(meta_key)
	local base_date = current_value or os.date("%Y-%m-%d")
	local year, month, day = base_date:match("(%d+)%-(%d+)%-(%d+)")
	if not (year and month and day) then
		return
	end

	local timestamp = os.time({
		year = tonumber(year) --[[@as integer]],
		month = tonumber(month) --[[@as integer]],
		day = tonumber(day) --[[@as integer]],
	})
	local adjusted = timestamp + delta * 24 * 60 * 60
	local new_date = os.date("%Y-%m-%d", adjusted)

	todo:set_meta_value(meta_key, new_date)
	vim.api.nvim_buf_set_lines(0, row - 1, row, false, { todo:render() })
	highlight_dates()
end

for _, m in ipairs({
	{ "<space>dm", "due", -1, "Decrease due date by 1 day" },
	{ "<space>dp", "due", 1, "Increase due date by 1 day" },
	{ "<space>tm", "t", -1, "Decrease threshold date by 1 day" },
	{ "<space>tp", "t", 1, "Increase threshold date by 1 day" },
}) do
	vim.keymap.set("n", m[1], function()
		adjust_meta_date(m[2], m[3])
	end, { buffer = 0, desc = m[4] })
end

-- Sort todo.txt: due → threshold → context → alphabetical
local function sort_buffer()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local indexed_lines = {}

	for _, line in ipairs(lines) do
		local todo = TodoLine.parse(line)
		local first_context = todo.contexts[1]
		table.insert(indexed_lines, {
			line = line,
			due = todo:get_meta_value("due") or "",
			threshold = todo:get_meta_value("t") or "",
			context = first_context and first_context:sub(2) or "",
		})
	end

	table.sort(indexed_lines, function(a, b)
		-- Empty values go last in each tier
		local function cmp(va, vb)
			if va == "" and vb == "" then
				return nil
			end
			if va == "" then
				return false
			end
			if vb == "" then
				return true
			end
			if va ~= vb then
				return va < vb
			end
			return nil
		end

		local r = cmp(a.due, b.due)
		if r ~= nil then
			return r
		end

		r = cmp(a.threshold, b.threshold)
		if r ~= nil then
			return r
		end

		r = cmp(a.context, b.context)
		if r ~= nil then
			return r
		end

		return a.line < b.line
	end)

	local sorted_lines = vim.tbl_map(function(item)
		return item.line
	end, indexed_lines)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, sorted_lines)
	highlight_dates()
end

vim.api.nvim_buf_create_user_command(
	0,
	"Sort",
	sort_buffer,
	{ desc = "Sort by due, threshold, context, then alphabetically" }
)
vim.api.nvim_buf_create_user_command(0, "Format", format_buffer, { desc = "Normalize todo.txt tokens" })

-- Diagnostics for missing priority/context
local ns = vim.api.nvim_create_namespace("todotxt_diagnostics")

local function update_diagnostics()
	local diagnostics = {}
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for lnum, line in ipairs(lines) do
		local todo = TodoLine.parse(line)
		if #todo.tokens > 0 and todo.prefix[1] ~= "x" then
			if not todo.priority then
				table.insert(diagnostics, {
					lnum = lnum - 1,
					col = 0,
					message = "Missing priority",
					severity = vim.diagnostic.severity.ERROR,
				})
			end

			if #todo.contexts == 0 then
				table.insert(diagnostics, {
					lnum = lnum - 1,
					col = 0,
					message = "Missing context",
					severity = vim.diagnostic.severity.ERROR,
				})
			end
		end
	end

	vim.diagnostic.set(ns, 0, diagnostics)
end

-- Set up autocommands to refresh highlights
local augroup = vim.api.nvim_create_augroup("TodoTxtHighlight", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertEnter", "InsertLeave", "TextChanged" }, {
	group = augroup,
	buffer = 0,
	callback = function()
		highlight_dates()
		update_diagnostics()
	end,
})

-- Initial highlight and diagnostics
highlight_dates()
update_diagnostics()
