vim.opt_local.undofile = false
vim.opt_local.swapfile = false
vim.opt_local.backup = false
vim.opt_local.writebackup = false

local pass_tmp_pattern = "*/pass.*/*-*.txt"
if not vim.tbl_contains(vim.opt.backupskip:get(), pass_tmp_pattern) then
	vim.opt.backupskip:append({ pass_tmp_pattern })
end
