vim.opt_local.undofile = false

local pass_tmp_pattern = "*/pass.*/*-*.txt"
if not vim.tbl_contains(vim.opt.backupskip:get(), pass_tmp_pattern) then
	vim.opt.backupskip:append({ pass_tmp_pattern })
end
