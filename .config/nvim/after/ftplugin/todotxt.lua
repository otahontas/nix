local utils = require("utils")
utils.disable_hard_wrap_for_buffer(0)

-- Spellcheck for todotxt files
vim.opt_local.spell = true

-- toggle done with commentstring
vim.bo.commentstring = "x %s"

-- Date patterns
local PATTERNS = {
  due = "due:(%d%d%d%d%-%d%d%-%d%d)",
  threshold = "t:(%d%d%d%d%-%d%d%-%d%d)",
  completed = "^x %d%d%d%d%-%d%d%-%d%d",
}

-- Valid sort types
local VALID_SORT_TYPES = { due = true, threshold = true, project = true, context = true, }

-- Cache today's date
local today = os.date("%Y-%m-%d")

-- Highlight overdue and active threshold dates
local due_match_id = nil
local threshold_match_id = nil

local function highlight_dates ()
  -- Clear existing highlights
  if due_match_id then
    pcall(vim.fn.matchdelete, due_match_id)
    due_match_id = nil
  end
  if threshold_match_id then
    pcall(vim.fn.matchdelete, threshold_match_id)
    threshold_match_id = nil
  end

  today = os.date("%Y-%m-%d") -- Refresh cached date
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local due_positions = {}
  local threshold_positions = {}

  for lnum, line in ipairs(lines) do
    -- Skip completed tasks
    if line:match(PATTERNS.completed) then
      goto continue
    end

    -- Check for overdue tasks
    local due_start, due_end, date = line:find(PATTERNS.due)
    if date and date <= today then
      table.insert(due_positions, { lnum, due_start, due_end - due_start + 1, })
    end

    -- Check for active threshold dates
    local t_start, t_end, date = line:find(PATTERNS.threshold)
    if date and date <= today then
      table.insert(threshold_positions, { lnum, t_start, t_end - t_start + 1, })
    end

    ::continue::
  end

  if #due_positions > 0 then
    due_match_id = vim.fn.matchaddpos("ErrorMsg", due_positions, 10)
  end
  if #threshold_positions > 0 then
    threshold_match_id = vim.fn.matchaddpos("DiagnosticInfo", threshold_positions, 10)
  end
end

-- Token classifiers

-- Formatting helpers
local function is_iso_date (token)
  return token:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil
end

local function is_priority_token (token)
  return token:match("^%([A-Z]%)$") ~= nil
end

local function is_context_token (token)
  return token:match("^@%S+$") ~= nil
end

local function is_project_token (token)
  return token:match("^%+%S+$") ~= nil
end

local function is_key_value_token (token)
  if not token:match("^[^%s:]+:[^%s]+$") then return false end
  if token:match("://") then return false end
  return true
end

local function extend (into, values)
  for _, value in ipairs(values) do
    table.insert(into, value)
  end
end

local TodoLine = {}
TodoLine.__index = TodoLine

function TodoLine.parse (line)
  local trimmed = vim.trim(line)
  local tokens = (trimmed == "") and {} or vim.split(trimmed, "%s+", { trimempty = true, })

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
    meta = { due = {}, t = {}, est = {}, other = {}, },
  }

  setmetatable(obj, TodoLine)

  if #tokens == 0 then return obj end

  local idx = 1
  if tokens[idx] == "x" then
    table.insert(obj.prefix, tokens[idx])
    idx = idx + 1
    while tokens[idx] and is_iso_date(tokens[idx]) do
      table.insert(obj.prefix, tokens[idx])
      idx = idx + 1
    end
  end

  for position = idx, #tokens do
    local token = tokens[position]
    if not obj.priority and is_priority_token(token) then
      obj.priority = token
    elseif is_context_token(token) then
      table.insert(obj.contexts, token)
    elseif is_project_token(token) then
      table.insert(obj.projects, token)
    elseif is_key_value_token(token) then
      local key = token:match("^([^:]+):")
      if obj.meta[key] then
        table.insert(obj.meta[key], token)
      else
        table.insert(obj.meta.other, token)
      end
    else
      table.insert(obj.description, token)
    end
  end

  return obj
end

function TodoLine:get_meta_value (key)
  local bucket = self.meta[key]
  if not bucket or not bucket[1] then return nil end
  return bucket[1]:match(":(%S+)$")
end

function TodoLine:set_meta_value (key, date_str)
  local bucket = self.meta[key]
  if not bucket then
    bucket = {}
    self.meta[key] = bucket
  end
  local token = key .. ":" .. date_str
  if bucket[1] then
    bucket[1] = token
  else
    table.insert(bucket, token)
  end
end

function TodoLine:render ()
  if #self.tokens == 0 then return self.raw end

  local reordered = {}
  extend(reordered, self.prefix)
  if self.priority then table.insert(reordered, self.priority) end
  extend(reordered, self.description)
  extend(reordered, self.contexts)
  extend(reordered, self.projects)
  extend(reordered, self.meta.due)
  extend(reordered, self.meta.t)
  extend(reordered, self.meta.est)
  extend(reordered, self.meta.other)

  local rebuilt = table.concat(reordered, " ")
  return self.leading .. rebuilt .. self.trailing
end

local function format_buffer ()
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

local function adjust_meta_date (meta_key, delta)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  if line == "" then return end

  local todo = TodoLine.parse(line)
  if #todo.tokens == 0 then return end

  local current_value = todo:get_meta_value(meta_key)
  local base_date = current_value or os.date("%Y-%m-%d")
  local year, month, day = base_date:match("(%d+)%-(%d+)%-(%d+)")
  if not (year and month and day) then return end

  local timestamp = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
  })
  timestamp = timestamp + delta * 24 * 60 * 60
  local new_date = os.date("%Y-%m-%d", timestamp)

  todo:set_meta_value(meta_key, new_date)
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { todo:render(), })
  highlight_dates()
end

local function adjust_due_date (delta)
  adjust_meta_date("due", delta)
end

local function adjust_threshold_date (delta)
  adjust_meta_date("t", delta)
end

local function map_date_delta (lhs, delta, fn, desc)
  vim.keymap.set("n", lhs, function()
    fn(delta)
  end, { buffer = 0, desc = desc, })
end

map_date_delta("<space>dm", -1, adjust_due_date, "Decrease due date by 1 day")
map_date_delta("<space>dp", 1, adjust_due_date, "Increase due date by 1 day")
map_date_delta("<space>tm", -1, adjust_threshold_date, "Decrease threshold date by 1 day")
map_date_delta("<space>tp", 1, adjust_threshold_date, "Increase threshold date by 1 day")

-- Sort todo.txt by various criteria
local function tsort (sort_spec)
  -- Parse sort specification (e.g., "due,threshold" or just "due")
  local parts = vim.split(sort_spec, ",", { plain = true, })
  local primary = vim.trim(parts[1])
  local secondary = parts[2] and vim.trim(parts[2]) or nil

  -- Validate sort types
  if not VALID_SORT_TYPES[primary] then
    vim.notify(
      "Invalid primary sort type. Use 'due', 'threshold', 'project', or 'context'",
      vim.log.levels.WARN)
    return
  end
  if secondary and not VALID_SORT_TYPES[secondary] then
    vim.notify(
      "Invalid secondary sort type. Use 'due', 'threshold', 'project', or 'context'",
      vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local indexed_lines = {}

  local function extract_value (todo, sort_type)
    if sort_type == "due" then return todo:get_meta_value("due") or "" end
    if sort_type == "threshold" then return todo:get_meta_value("t") or "" end
    if sort_type == "project" then
      local first = todo.projects[1]
      return first and first:sub(2) or ""
    end
    if sort_type == "context" then
      local first = todo.contexts[1]
      return first and first:sub(2) or ""
    end
    return ""
  end

  for _, line in ipairs(lines) do
    local todo = TodoLine.parse(line)
    table.insert(indexed_lines, {
      line = line,
      primary = extract_value(todo, primary),
      secondary = secondary and extract_value(todo, secondary) or nil,
    })
  end

  -- Helper to compare values (empty values go last)
  local function compare_values (a, b)
    if a == "" and b == "" then return false end
    if a == "" then return false end
    if b == "" then return true end
    return a < b
  end

  -- Sort with optional secondary value
  table.sort(indexed_lines, function(a, b)
    -- Primary sort
    if a.primary ~= b.primary then
      local result = compare_values(a.primary, b.primary)
      if result ~= nil then return result end
    end

    -- Secondary sort (if specified)
    if secondary and a.secondary ~= b.secondary then
      local result = compare_values(a.secondary, b.secondary)
      if result ~= nil then return result end
    end

    -- Tertiary: alphabetical
    return a.line < b.line
  end)

  -- Extract sorted lines
  local sorted_lines = {}
  for _, item in ipairs(indexed_lines) do
    table.insert(sorted_lines, item.line)
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, sorted_lines)
  highlight_dates()
end

vim.api.nvim_buf_create_user_command(0, "Sort", function(opts)
  tsort(opts.args)
end, {
  nargs = 1,
  complete = function()
    return {
      "due",
      "due,threshold",
      "threshold",
      "threshold,due",
      "project",
      "project,due",
      "context",
      "context,due",
    }
  end,
})

vim.api.nvim_buf_create_user_command(0, "Format", function()
  format_buffer()
end, {
  desc = "Normalize todo.txt tokens",
})

-- Set up autocommands to refresh highlights
local augroup = vim.api.nvim_create_augroup("TodoTxtHighlight", { clear = true, })
vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertLeave", "TextChanged", }, {
  group = augroup,
  buffer = 0,
  callback = highlight_dates,
})

-- Initial highlight
highlight_dates()
