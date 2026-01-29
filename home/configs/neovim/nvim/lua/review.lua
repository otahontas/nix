-- Code review module for local PR-style reviews
-- Creates .review files next to source files with structured comments

local M = {}

-- Review comment types
M.types = {
	{ key = "f", name = "must-fix", desc = "Must be fixed before merge" },
	{ key = "s", name = "suggestion", desc = "Consider this improvement" },
	{ key = "q", name = "question", desc = "Need clarification" },
	{ key = "n", name = "nit", desc = "Minor/style issue" },
	{ key = "p", name = "praise", desc = "Good work!" },
}

-- Get the review file path for a given source file
function M.get_review_path(source_path)
	return source_path .. ".review"
end

-- Parse existing review file
function M.parse_review(review_path)
	local review = {
		status = nil,
		comments = {},
	}

	local file = io.open(review_path, "r")
	if not file then
		return review
	end

	local content = file:read("*all")
	file:close()

	-- Parse status
	local status = content:match("%*%*Status:%*%* ([%w-]+)")
	review.status = status

	-- Parse comments (## L42 | must-fix format)
	for line_spec, comment_type, comment_text in content:gmatch("## (L[%d-]+) | ([%w-]+)\n(.-)(?=\n## |$)") do
		table.insert(review.comments, {
			line = line_spec,
			type = comment_type,
			text = vim.trim(comment_text),
		})
	end

	return review
end

-- Write review to file
function M.write_review(review_path, review, filename)
	local lines = {
		"# Review: " .. filename,
		"",
		"**Status:** " .. (review.status or "in-progress"),
		"",
	}

	if #review.comments > 0 then
		for _, comment in ipairs(review.comments) do
			table.insert(lines, "## " .. comment.line .. " | " .. comment.type)
			table.insert(lines, comment.text)
			table.insert(lines, "")
		end
	end

	local file = io.open(review_path, "w")
	if file then
		file:write(table.concat(lines, "\n"))
		file:close()
		return true
	end
	return false
end

-- Add a review comment at current cursor position
function M.add_comment()
	-- Get current file info from diffview or regular buffer
	local bufnr = vim.api.nvim_get_current_buf()
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor[1]

	-- Handle diffview buffers - extract original file path
	local source_path = bufname
	if bufname:match("^diffview://") then
		-- Extract path from diffview URI
		-- Format: diffview://path/to/file.ts or similar
		source_path = bufname:gsub("^diffview://[^/]+/", "")
		-- Try to resolve to actual file path
		local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+", "")
		if git_root ~= "" then
			source_path = git_root .. "/" .. source_path
		end
	end

	-- Make path relative to git root for cleaner review files
	local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+", "")
	local relative_path = source_path
	if git_root ~= "" and source_path:sub(1, #git_root) == git_root then
		relative_path = source_path:sub(#git_root + 2)
	end

	-- Build type selection prompt
	local type_options = {}
	for _, t in ipairs(M.types) do
		table.insert(type_options, string.format("[%s] %s - %s", t.key, t.name, t.desc))
	end

	vim.ui.select(type_options, {
		prompt = "Comment type:",
	}, function(choice)
		if not choice then
			return
		end

		-- Extract type from choice
		local type_key = choice:match("%[(%w)%]")
		local comment_type = nil
		for _, t in ipairs(M.types) do
			if t.key == type_key then
				comment_type = t.name
				break
			end
		end

		if not comment_type then
			return
		end

		-- Get comment text
		vim.ui.input({
			prompt = string.format("[%s] L%d comment: ", comment_type, line_num),
		}, function(comment_text)
			if not comment_text or comment_text == "" then
				return
			end

			-- Load or create review
			local review_path = M.get_review_path(source_path)
			local review = M.parse_review(review_path)

			-- Add new comment
			table.insert(review.comments, {
				line = "L" .. line_num,
				type = comment_type,
				text = comment_text,
			})

			-- Write review
			local filename = vim.fn.fnamemodify(source_path, ":t")
			if M.write_review(review_path, review, filename) then
				vim.notify(string.format("Added %s comment at L%d", comment_type, line_num), vim.log.levels.INFO)
			else
				vim.notify("Failed to write review file", vim.log.levels.ERROR)
			end
		end)
	end)
end

-- Set review status for current file
function M.set_status()
	local bufname = vim.api.nvim_buf_get_name(0)
	local source_path = bufname

	-- Handle diffview buffers
	if bufname:match("^diffview://") then
		source_path = bufname:gsub("^diffview://[^/]+/", "")
		local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+", "")
		if git_root ~= "" then
			source_path = git_root .. "/" .. source_path
		end
	end

	local statuses = {
		"approved",
		"request-changes",
		"in-progress",
	}

	vim.ui.select(statuses, {
		prompt = "Set review status:",
	}, function(choice)
		if not choice then
			return
		end

		local review_path = M.get_review_path(source_path)
		local review = M.parse_review(review_path)
		review.status = choice

		local filename = vim.fn.fnamemodify(source_path, ":t")
		if M.write_review(review_path, review, filename) then
			vim.notify(string.format("Set status to: %s", choice), vim.log.levels.INFO)
		else
			vim.notify("Failed to write review file", vim.log.levels.ERROR)
		end
	end)
end

-- Open the review file for current source file
function M.open_review()
	local bufname = vim.api.nvim_buf_get_name(0)
	local source_path = bufname

	if bufname:match("^diffview://") then
		source_path = bufname:gsub("^diffview://[^/]+/", "")
		local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+", "")
		if git_root ~= "" then
			source_path = git_root .. "/" .. source_path
		end
	end

	local review_path = M.get_review_path(source_path)
	vim.cmd("vsplit " .. review_path)
end

-- List all review files in the repo
function M.list_reviews()
	local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+", "")
	if git_root == "" then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local reviews = vim.fn.glob(git_root .. "/**/*.review", false, true)
	if #reviews == 0 then
		vim.notify("No review files found", vim.log.levels.INFO)
		return
	end

	vim.ui.select(reviews, {
		prompt = "Review files:",
		format_item = function(path)
			return path:gsub(git_root .. "/", "")
		end,
	}, function(choice)
		if choice then
			vim.cmd("edit " .. choice)
		end
	end)
end

-- Delete all review files in the repo
function M.clear_reviews()
	local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("%s+", "")
	if git_root == "" then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local reviews = vim.fn.glob(git_root .. "/**/*.review", false, true)
	if #reviews == 0 then
		vim.notify("No review files to clear", vim.log.levels.INFO)
		return
	end

	vim.ui.select({ "Yes, delete all " .. #reviews .. " review files", "No, cancel" }, {
		prompt = "Clear all reviews?",
	}, function(choice)
		if choice and choice:match("^Yes") then
			for _, path in ipairs(reviews) do
				os.remove(path)
			end
			vim.notify(string.format("Deleted %d review files", #reviews), vim.log.levels.INFO)
		end
	end)
end

-- Setup keymaps
function M.setup()
	local set = vim.keymap.set
	set("n", "<leader>rc", M.add_comment, { desc = "Review: add comment" })
	set("n", "<leader>rs", M.set_status, { desc = "Review: set status" })
	set("n", "<leader>ro", M.open_review, { desc = "Review: open review file" })
	set("n", "<leader>rl", M.list_reviews, { desc = "Review: list all reviews" })
	set("n", "<leader>rx", M.clear_reviews, { desc = "Review: clear all reviews" })
end

return M
