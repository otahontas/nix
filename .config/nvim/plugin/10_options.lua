-- Set global defaults that differ from nvim defaults
vim.iter({
  -- Always create backup files
  backup = true,
  -- Wrapped lines maintain same indentation as first line
  breakindent = true,
  -- Reduce indent by 1 for wrapped list items (works with formatlistpat)
  breakindentopt = "list:-1",
  -- Show column at textwidth+1 as visual guide
  colorcolumn = "+1",
  -- Prompt to save on quit if there are unsaved changes
  confirm = true,
  -- Highlight the line where cursor is located
  cursorline = true,
  -- Highlight screen line and line number (not entire wrapped line)
  cursorlineopt = "screenline,number",
  -- Use spaces instead of tab characters
  expandtab = true,
  -- Load .nvim.lua/.nvimrc/.exrc from current directory (prompts first)
  exrc = true,
  -- Nice unicode characters for visualizing folds, splits, and separators
  fillchars = {
    eob = "?", -- ?
    fold = " ", -- Fill for closed folds
    foldclose = "", -- Unicode right arrow for closed folds
    foldopen = "", -- Unicode down arrow for open folds
    foldsep = " ", -- no fold separator (shown between folds)
    foldinner = " ", -- no inner fold lines (shown inside fold area)
    msgsep = "─",
  },
  -- Width of fold indicator column on left side (string for auto-sizing)
  foldcolumn = "1",
  -- All folds start closed at this level when opening file
  foldlevelstart = 1,
  -- Create folds based on indentation levels
  foldmethod = "indent",
  -- Maximum nested fold depth
  foldnestmax = 10,
  -- Regex for list item recognition: ^\s* (leading whitespace)
  -- [0-9\-\+\*]\+ (number/dash/plus/asterisk) [\.\)]* (optional dot/paren)
  -- \s\+ (required trailing whitespace)
  formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]],
  -- r: auto-insert comment leader after <Enter>
  -- q: allow formatting comments with gq
  -- n: recognize numbered lists
  -- l: don't break long lines in insert mode
  -- 1: don't break before 1-letter words
  -- j: remove comment leader when joining lines
  formatoptions = "rqnl1j",
  -- Show live preview in split window for substitution commands
  inccommand = "split",
  -- Adjust case of completion matches based on typed text
  infercase = true,
  -- Characters considered part of a word: @ (all letters), 48-57 (digits 0-9),
  -- _ (underscore), 192-255 (extended ASCII/accented chars), - (dash)
  iskeyword = "@,48-57,_,192-255,-",
  -- Single global statusline at bottom (not per-window)
  laststatus = 3,
  -- Break wrapped lines at word boundaries instead of mid-word
  linebreak = true,
  -- Nice unicode characters for visualizing whitespace
  listchars = {
    nbsp = "¬",
    eol = "¶",
    tab = ">-",
    extends = "»",
    precedes = "«",
    trail = "•",
  },
  -- Enable mouse in all modes
  mouse = "a",
  -- Show absolute line numbers
  number = true,
  -- Show relative line numbers (distance from cursor line)
  relativenumber = true,
  -- Don't show cursor position in bottom right
  ruler = false,
  -- Keep 10 lines visible above and below cursor when scrolling
  scrolloff = 10,
  -- ShaDa (session data) settings: '100 (marks for 100 files),
  -- <50 (50 lines per register), s10 (10KB per item),
  -- :1000 (1000 command history), /100 (100 search history),
  -- @100 (100 input history), h (disable hlsearch on start)
  shada = "'100,<50,s10,:1000,/100,@100,h",
  -- Number of spaces for >> and << indent operations
  shiftwidth = 2,
  -- Briefly jump cursor to matching bracket when closing one
  showmatch = true,
  -- Don't show mode text (INSERT, VISUAL, etc) in command line
  showmode = false,
  -- Always show sign column (for git signs, LSP diagnostics, etc)
  signcolumn = "yes",
  -- Case-insensitive search unless query contains uppercase
  smartcase = true,
  -- Automatically indent new lines intelligently
  smartindent = true,
  -- Number of spaces inserted when pressing tab in insert mode
  softtabstop = 2,
  -- Enable spell checking
  spell = true,
  -- Recognize camelCase words for spell checking
  spelloptions = "camel",
  -- Open horizontal splits below current window
  splitbelow = true,
  -- Maintain cursor screen position when splitting windows
  splitkeep = "screen",
  -- Open vertical splits to right of current window
  splitright = true,
  -- Jump to existing tab if buffer is already open there
  switchbuf = "usetab",
  -- Width of actual tab character when displayed
  tabstop = 2,
  -- Line length for gq formatting (not automatic wrapping)
  textwidth = 88,
  -- Delay in ms before multi-key mappings timeout
  timeoutlen = 400,
  -- Persist undo history to file between sessions
  undofile = true,
  -- Faster CursorHold trigger (ms) for LSP hover/diagnostics
  updatetime = 250,
  -- Allow cursor to move beyond line end in visual block mode
  virtualedit = "block",
  -- Rounded borders for floating windows (requires nvim 0.11+)
  winborder = "rounded",
  -- Don't wrap long lines visually
  wrap = false,
}):each(function(option, value)
  vim.opt[option] = value
end)


-- Don't save backups in same folder
vim.opt.backupdir:remove({ ".", })

-- Use patience algo for diffing
vim.opt.diffopt:append({ "algorithm:patience", })

-- Setup clipboard, but don't block on startup
vim.defer_fn(function()
  vim.o.clipboard = "unnamedplus"
end, 0)

-- Setup diagnostics, but don't block on startup
vim.defer_fn(
  function()
    vim.diagnostic.config({
      -- Show signs on top of any other sign, but only for warnings and errors
      signs = {
        priority = 9999,
        severity = {
          min = vim.diagnostic.severity.WARN,
          max = vim.diagnostic.severity.ERROR,
        },
      },
      -- Show all diagnostics as underline to reduce clutter
      underline = {
        severity = {
          min = vim.diagnostic.severity.HINT,
          max = vim.diagnostic.severity.ERROR,
        },
      },
      -- Don't update diagnostics when typing
      update_in_insert = false,
      -- Show more details immediately for errors on the current line
      virtual_lines = false,
      virtual_text = {
        current_line = true,
        severity = {
          min = vim.diagnostic.severity.ERROR,
          max = vim.diagnostic.severity.ERROR,
        },
      },
    })
  end,
  0
)

-- Explicitly enable filetype detection and syntax highlighting
-- (usually enabled by default but some plugins may require explicit call)
vim.cmd("filetype plugin indent on")
if vim.fn.exists("syntax_on") ~= 1 then
  vim.cmd("syntax enable")
end

-- Enable couple of nice plugins, but don't block on startup
vim.defer_fn(function()
  vim.cmd("packadd nvim.difftool")
  vim.cmd("packadd nvim.undotree")
end, 0)

-- Add command for running pack.update
vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update({})
end, { desc = "Update all plugins", })
