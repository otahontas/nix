-- Use mini git for folding git diffs
vim.cmd("setlocal foldmethod=expr foldexpr=v:lua.MiniGit.diff_foldexpr()")
