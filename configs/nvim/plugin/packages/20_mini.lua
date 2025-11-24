require("utils").add_package({ "https://github.com/nvim-mini/mini.nvim", },
  function()
    -- Setup mini modules

    -- with default settings
    require("mini.git").setup()
    require("mini.notify").setup()
    require("mini.pairs").setup()
    require("mini.statusline").setup()
    require("mini.surround").setup()

    -- with non-default settings
    require("mini.diff").setup({
      -- use signs always
      view = {
        style = "sign",
        signs = { add = "▒", change = "▒", delete = "▒", },
      },
      options = {
        algorithm = "patience",
        wrap_goto = true,
      },
    })
    require("mini.indentscope").setup({
      draw = {
        -- Skip animation
        animation = require("mini.indentscope").gen_animation.none(),
      },
    })
    local miniMap = require("mini.map")
    miniMap.setup({
      integrations = {
        miniMap.gen_integration.builtin_search(),
        miniMap.gen_integration.diff(),
        miniMap.gen_integration.diagnostic(),
      },
    })
    vim.keymap.set("n", "<Leader>mmt", miniMap.toggle)
    vim.keymap.set("n", "<Leader>mmf", miniMap.toggle_focus)

    -- Open diff overlay
    vim.keymap.set("n", "<Leader>do", "<Cmd>lua MiniDiff.toggle_overlay()<CR>",
      { desc = "Toggle mini diff overlay", })


    -- setup and mock exported functions of 'nvim-tree/nvim-web-devicons' (for octo that has no support for mini.icons yet)
    local miniIcons = require("mini.icons")
    miniIcons.setup()
    miniIcons.mock_nvim_web_devicons()

    -- show notification history for mini
    vim.keymap.set("n", "<Leader>mnsh", "<Cmd>lua MiniNotify.show_history()<CR>",
      { desc = "Show notification history", })

    -- navigate to git info at cursor
    local show_at_cursor = "<Cmd>lua MiniGit.show_at_cursor()<CR>"
    vim.keymap.set({ "n", "x", }, "<Leader>gs", show_at_cursor,
      { desc = "Show at cursor", })

    -- fast blame
    local git_blame = "<Cmd>vert Git blame -- %<CR>"
    vim.keymap.set({ "n", "x", }, "<Leader>gb", git_blame, { desc = "Show at cursor", })

    -- Better looking & working git blame setup (colors + sync scroll + width):
    -- https://github.com/nvim-mini/mini.nvim/discussions/2029
    vim.api.nvim_set_hl(0, "GitBlameHashRoot", { link = "Tag", })
    vim.api.nvim_set_hl(0, "GitBlameHash", { link = "Identifier", })
    vim.api.nvim_set_hl(0, "GitBlameAuthor", { link = "String", })
    vim.api.nvim_set_hl(0, "GitBlameDate", { link = "Comment", })

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniGitCommandSplit",
      callback = function(e)
        if e.data.git_subcommand ~= "blame" then
          return
        end
        local win_src = e.data.win_source
        local buf = e.buf
        local win = e.data.win_stdout
        -- Opts
        vim.bo[buf].modifiable = false
        vim.wo[win].wrap = false
        vim.wo[win].cursorline = true
        -- View
        vim.fn.winrestview({ topline = vim.fn.line("w0", win_src), })
        vim.api.nvim_win_set_cursor(0, { vim.fn.line(".", win_src), 0, })
        vim.wo[win].scrollbind, vim.wo[win_src].scrollbind = true, true
        vim.wo[win].cursorbind, vim.wo[win_src].cursorbind = true, true
        -- Vert width
        if e.data.cmd_input.mods:match("vertical") then
          local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)
          local width = vim.iter(lines):fold(-1, function(acc, ln)
            local stat = string.match(ln, "^%S+ %b()")
            return math.max(acc, vim.fn.strwidth(stat))
          end)
          width = width + vim.fn.getwininfo(win)[1].textoff
          vim.api.nvim_win_set_width(win, width)
        end
        -- Highlight
        vim.fn.matchadd("GitBlameHashRoot", [[^^\w\+]])
        vim.fn.matchadd("GitBlameHash", [[^\w\+]])
        local leftmost = [[^.\{-}\zs]]
        vim.fn.matchadd("GitBlameAuthor", leftmost .. [[(\zs.\{-} \ze\d\{4}-]])
        vim.fn.matchadd("GitBlameDate", leftmost .. [[[0-9-]\{10} [0-9:]\{8} [+-]\d\+]])
      end,
    })
  end)
