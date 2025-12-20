local utils = require("utils")

local NS = { namespace = "gh", }
local NS_ALLOW_EMPTY = { namespace = "gh", allow_empty = true, }

local function get_relative_path(file)
  return utils.run_cmd({ "git", "ls-files", "--full-name", file, }, NS)
end

local function file_is_dirty(rel_path)
  local out = utils.run_cmd({ "git", "status", "--porcelain", "--", rel_path, },
    NS_ALLOW_EMPTY)
  return out ~= ""
end

local function get_commit()
  return utils.run_cmd({ "git", "rev-parse", "HEAD", }, NS)
end

local function is_commit_pushed(commit)
  local upstream = utils.run_cmd({
    "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}",
  }, NS)
  return utils.run_cmd({ "git", "merge-base", "--is-ancestor", commit, upstream, },
    NS_ALLOW_EMPTY) ~= nil
end

local function get_repo_url()
  return utils.run_cmd({ "gh", "repo", "view", "--json", "url", "--jq", ".url", }, NS)
end

local M = {}

M.copy_github_permalink = function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("gh: buffer has no file on disk", vim.log.levels.WARN)
    return
  end

  local rel_path = get_relative_path(file)
  if not rel_path then return end

  if file_is_dirty(rel_path) then
    vim.notify("gh: file has uncommitted changes", vim.log.levels.WARN)
    return
  end

  local commit = get_commit()
  if not commit then return end

  if not is_commit_pushed(commit) then
    vim.notify("gh: commit not pushed to remote", vim.log.levels.WARN)
    return
  end

  local repo_url = get_repo_url()
  if not repo_url then return end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local url = string.format("%s/blob/%s/%s#L%d", repo_url, commit, rel_path, line)

  vim.fn.setreg("+", url)
  pcall(vim.fn.setreg, "*", url)
  vim.notify("gh: copied permalink for line " .. line, vim.log.levels.INFO)
end

return M
