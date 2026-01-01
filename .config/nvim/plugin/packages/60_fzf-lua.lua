local utils = require("utils")
local set = vim.keymap.set

-- TODO: sync keymaps to be as close to yazi as possible (or other way around)
-- NOTE: This will take time
utils.add_package({ "https://github.com/ibhagwan/fzf-lua", },
  function()
    -- Get project root using LSP workspace, fallback to .git
    local function get_project_root ()
      local workspace_folders = vim.lsp.buf.list_workspace_folders()
      if workspace_folders and #workspace_folders > 0 then
        return workspace_folders[1]
      end
      return utils.get_closest_ancestor_directory_that_has_file(".git")
    end

    -- load fzf & setup keymaps
    local fzf = require("fzf-lua")
    fzf.setup({
      -- mini is needed for the icons
      defaults = { git_icons = "true", file_icons = "mini", },
    })

    -- generic
    set("n", "<leader>fzf", "<cmd>FzfLua<cr>", { desc = "Open FZF", })

    -- files
    set("n", "<leader>fdd", "<cmd>FzfLua files<cr>", { desc = "Find files", })
    set("n", "<leader>fdc", function()
      fzf.files({ cwd = utils.get_current_directory(), })
    end, { desc = "Find files in current file's directory", })
    set("n", "<leader>fdp", function()
      fzf.files({ cwd = get_project_root(), })
    end, { desc = "Find files in workspace directory", })

    -- grep
    set("n", "<leader>rgg", "<cmd>FzfLua grep<cr>", { desc = "Grep files", })
    set("n", "<leader>rgc", function()
      fzf.grep({ cwd = utils.get_current_directory(), })
    end, { desc = "Grep in current file's directory", })
    set("n", "<leader>rgp", function()
      fzf.grep({ cwd = get_project_root(), })
    end, { desc = "Grep in workspace directory", })
  end
)
