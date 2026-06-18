local utils = require("utils")

local NS = { namespace = "gh" }

local function run_in_repo(cmd, repo_root, allow_empty)
	local out = utils.run_cmd(cmd, {
		namespace = "gh",
		allow_empty = allow_empty,
		cwd = repo_root,
	})
	return out and vim.trim(out) or nil
end

local function get_repo_root(file)
	local dir = vim.fn.fnamemodify(file, ":h")
	local out = utils.run_cmd({ "git", "-C", dir, "root" }, NS)
	return out and vim.trim(out) or nil
end

local function get_relative_path(file, repo_root)
	return run_in_repo({ "git", "ls-files", "--full-name", file }, repo_root)
end

local function file_is_dirty(rel_path, repo_root)
	local out = run_in_repo({ "git", "status", "--porcelain", "--", rel_path }, repo_root, true)
	if out == nil then
		return nil
	end
	return out ~= ""
end

local function get_commit(repo_root)
	return run_in_repo({ "git", "rev-parse", "HEAD" }, repo_root)
end

local function is_commit_pushed(commit, repo_root)
	local upstream = run_in_repo({
		"git",
		"rev-parse",
		"--abbrev-ref",
		"--symbolic-full-name",
		"@{u}",
	}, repo_root)
	if not upstream then
		return nil
	end

	return run_in_repo({
		"git",
		"merge-base",
		"--is-ancestor",
		commit,
		upstream,
	}, repo_root, true) ~= nil
end

local function get_repo_url(repo_root)
	return run_in_repo({ "gh", "repo", "view", "--json", "url", "--jq", ".url" }, repo_root)
end

local M = {}

M.copy_github_permalink = function()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("gh: buffer has no file on disk", vim.log.levels.WARN)
		return
	end

	local repo_root = get_repo_root(file)
	if not repo_root then
		return
	end

	local rel_path = get_relative_path(file, repo_root)
	if not rel_path then
		return
	end

	local dirty = file_is_dirty(rel_path, repo_root)
	if dirty == nil then
		return
	end
	if dirty then
		vim.notify("gh: file has uncommitted changes", vim.log.levels.WARN)
		return
	end

	local commit = get_commit(repo_root)
	if not commit then
		return
	end

	if not is_commit_pushed(commit, repo_root) then
		vim.notify("gh: commit not pushed to remote", vim.log.levels.WARN)
		return
	end

	local repo_url = get_repo_url(repo_root)
	if not repo_url then
		return
	end

	local line = vim.api.nvim_win_get_cursor(0)[1]
	local url = string.format("%s/blob/%s/%s#L%d", repo_url, commit, rel_path, line)

	vim.fn.setreg("+", url)
	pcall(vim.fn.setreg, "*", url)
	vim.notify("gh: copied permalink for line " .. line, vim.log.levels.INFO)
end

return M
