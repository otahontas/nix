local M = {}

-- Run a shell command synchronously, notifying on failure
---@param cmd string[] command and arguments
---@param opts? { namespace?: string, allow_empty?: boolean }
---@return string|nil stdout (trimmed), nil on failure
M.run_cmd = function(cmd, opts)
  opts = opts or {}
  local namespace = opts.namespace or cmd[1]
  local cmd_str = table.concat(cmd, " ")

  local result = vim.system(cmd, { text = true, }):wait()
  if result.code ~= 0 then
    vim.notify(namespace .. ": `" .. cmd_str .. "` failed: " .. vim.trim(result.stderr),
      vim.log.levels.WARN)
    return nil
  end

  local out = vim.trim(result.stdout)
  if out == "" and not opts.allow_empty then
    vim.notify(namespace .. ": `" .. cmd_str .. "` returned empty", vim.log.levels.WARN)
    return nil
  end

  return out
end

-- Disable hard wrap and move withing soft wrapped lines with j and k
---@param bufnr number the buffer to disable hard wrap for. 0 is the current buffer
M.disable_hard_wrap_for_buffer = function(bufnr)
  vim.opt_local.linebreak = true
  vim.opt_local.textwidth = 0
  vim.keymap.set("n", "j", "gj", { buffer = bufnr, })
  vim.keymap.set("n", "k", "gk", { buffer = bufnr, })
end

-- Get current directory, falling back cwd when current directory is not available
M.get_current_directory = function()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    return vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(current_file, ":h")
end


-- Get closest ancestor directory that has the given file, falling back to cwd when
-- current directory is not available
---@param filename string the file to look for
M.get_closest_ancestor_directory_that_has_file = function(filename)
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    return vim.fn.getcwd()
  end
  local dir = vim.fn.fnamemodify(current_file, ":h")
  while dir ~= "/" do
    if vim.fn.filereadable(dir .. "/" .. filename) == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return vim.fn.getcwd() -- fallback to cwd if file not found
end

-- Setup buffer for prose editing (soft wrap, markdown link surround)
---@param bufnr number the buffer to setup. 0 is the current buffer
M.setup_prose_buffer = function(bufnr)
  M.disable_hard_wrap_for_buffer(bufnr)
  vim.opt_local.wrap = true -- enable soft wrap
  vim.b.minisurround_config = {
    custom_surroundings = {
      -- Markdown link: saiwL, sdL, srLL
      L = {
        input = { "%[().-()%]%(.-%)", },
        output = function()
          local link = require("mini.surround").user_input("Link: ")
          return { left = "[", right = "](" .. link .. ")", }
        end,
      },
    },
  }
end

-- Adds package with default settings and runs the setup callback
-- (setup doesn't call package.setup, it's just an arbitrary callback)
---@param specs any specs that should be installed
---@param setup? function setup callback that will be triggered after adding the package
M.add_package = function(specs, setup)
  vim.pack.add(specs, {
    load = true,
    confirm = false,
  })
  if setup then
    setup()
  end
end

return M
