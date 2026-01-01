local fn = vim.fn

local M = {}

local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "GitHub permalink", })
end

local function get_repo_root(file)
  local dir = fn.fnamemodify(file, ":h")
  local root_output = fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel", })
  if vim.v.shell_error ~= 0 or not root_output[1] or root_output[1] == "" then
    notify_error("Current file is not inside a git repository")
    return nil
  end
  return fn.trim(root_output[1])
end

local function get_relative_path(repo_root, file)
  local rel_output = fn.systemlist({ "git", "-C", repo_root, "ls-files", "--full-name", file, })
  if vim.v.shell_error ~= 0 or not rel_output[1] or rel_output[1] == "" then
    notify_error("Failed to determine file path inside repository")
    return nil
  end
  return rel_output[1]
end

local function file_is_dirty(repo_root, rel_path)
  local status_output = fn.systemlist({ "git", "-C", repo_root, "status", "--porcelain", "--", rel_path, })
  return status_output[1] and status_output[1] ~= ""
end

local function get_commit(repo_root, file)
  local dir = fn.fnamemodify(file, ":h")
  local commit_output = fn.systemlist({ "git", "-C", dir, "rev-parse", "HEAD", })
  if vim.v.shell_error ~= 0 or not commit_output[1] or commit_output[1] == "" then
    notify_error("Failed to resolve current commit")
    return nil
  end
  return fn.trim(commit_output[1])
end

local function ensure_commit_pushed(repo_root, commit)
  local upstream_output = fn.systemlist({
    "git",
    "-C",
    repo_root,
    "rev-parse",
    "--abbrev-ref",
    "--symbolic-full-name",
    "@{u}",
  })
  if vim.v.shell_error ~= 0 or not upstream_output[1] or upstream_output[1] == "" then
    notify_error("No upstream branch configured; push before copying a permalink")
    return false
  end

  local upstream = fn.trim(upstream_output[1])
  local push_check_cmd = string.format(
    "cd %s && git merge-base --is-ancestor %s %s",
    fn.shellescape(repo_root),
    fn.shellescape(commit),
    fn.shellescape(upstream)
  )
  fn.system(push_check_cmd)
  if vim.v.shell_error ~= 0 then
    notify_error("Can't copy URL for commits that have not been pushed yet")
    return false
  end

  return true
end

local function get_repo_url(repo_root)
  local repo_cmd = string.format(
    "cd %s && gh repo view --json url --jq .url",
    fn.shellescape(repo_root)
  )
  local repo_output = fn.systemlist(repo_cmd)
  if vim.v.shell_error ~= 0 or not repo_output[1] or repo_output[1] == "" then
    notify_error("gh repo view failed: " .. fn.trim(table.concat(repo_output, " ")))
    return nil
  end
  return fn.trim(repo_output[1])
end

M.copy_github_permalink = function()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    notify_error("Buffer has no file on disk")
    return
  end

  local repo_root = get_repo_root(file)
  if not repo_root then
    return
  end

  local rel_path = get_relative_path(repo_root, file)
  if not rel_path then
    return
  end

  if file_is_dirty(repo_root, rel_path) then
    notify_error("Can't copy URL for changes that are not committed yet")
    return
  end

  local commit = get_commit(repo_root, file)
  if not commit then
    return
  end

  if not ensure_commit_pushed(repo_root, commit) then
    return
  end

  local repo_url = get_repo_url(repo_root)
  if not repo_url then
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local url = string.format("%s/blob/%s/%s#L%d", repo_url, commit, rel_path, line)

  fn.setreg("+", url)
  pcall(fn.setreg, "*", url)
  vim.notify(
    "Copied permalink for line " .. line,
    vim.log.levels.INFO,
    { title = "GitHub permalink", }
  )
end

return M
