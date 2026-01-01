local set = vim.keymap.set

-- Use <space> as leader and localleader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Toggle hidden chars
set(
  "n",
  "<leader>sc",
  "<cmd>set invlist<cr>",
  { silent = true, desc = "Toggle hidden chars", }
)
-- Open terminal in current window
set(
  "n",
  "<leader>ss",
  "<cmd>terminal<cr>",
  { silent = true, desc = "Open terminal in current window", }
)
-- Open terminal in vertical split
set(
  "n",
  "<leader>vt",
  "<C-w>v<C-w>l<cmd>terminal<cr>",
  { silent = true, desc = "Open terminal in vertical split", }
)
-- Open terminal in horizontal split
set(
  "n",
  "<leader>st",
  "<C-w>s<C-w>j<cmd>terminal<cr>",
  { silent = true, desc = "Open terminal in horizontal split", }
)
-- Turn off highlighted search results
set(
  "n",
  "<leader>nh",
  "<cmd>nohlsearch<cr>",
  { silent = true, desc = "Turn off highlighted search results", }
)
-- Open new tab
set("n", "<leader>tn", "<cmd>tabnew<cr>", { silent = true, desc = "Open new tab", })
-- Save file
set("n", "<leader>ww", "<cmd>w!<cr>", { silent = false, desc = "Save file", })
-- Go to normal mode with Ctrl-W-Esc in terminal mode
set(
  "t",
  "<C-w><Esc>",
  "<C-\\><C-n>",
  { silent = true, desc = "Go to normal mode with Ctrl-W Esc in terminal mode", }
)
-- Copy github permalink for current line to clipboard
set(
  "n",
  "<leader>gy",
  require("gh").copy_github_permalink,
  { silent = true, desc = "Copy GitHub permalink for current line", }
)
