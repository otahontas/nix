require("utils").add_package({ "https://github.com/pwntester/octo.nvim", },
  function()
    require("octo").setup({
      picker = "fzf-lua",
      file_panel = {
        use_icons = false, -- TODO: make a PR that allows using mini icons
      },
      ui = {
        use_signcolumn = true, -- show "modified" marks on the sign column
        use_signstatus = true, -- show "modified" marks on the status column
      },
      mappings = {
        submit_win = {
          -- override the default submit mapping to use Alt instead of Ctrl
          -- (ctrl is already used by wezterm for ctrl-a & ctlr-m)
          approve_review = { lhs = "<M-a>", desc = "approve review", mode = { "n", "i", }, },
          comment_review = { lhs = "<M-m>", desc = "comment review", mode = { "n", "i", }, },
          request_changes = { lhs = "<M-r>", desc = "request changes review", mode = { "n", "i", }, },
        },
      },
    })
    -- parse markdown in octo buffers
    vim.treesitter.language.register("markdown", "octo")

    -- Todo autocompletion via blink?
    -- Omni:
    -- vim.keymap.set("i", "@", "@<C-x><C-o>", { silent = true, buffer = true })
    -- vim.keymap.set("i", "#", "#<C-x><C-o>", { silent = true, buffer = true })


    -- TODO: fix approving the review not working atm
    -- TODO: figure out way to go to next/prev changed line for easier review
    -- vim.keymap.set("n", "<leader>oca", "<cmd>Octo comment add<cr>", {
    --   desc = "Octo: add comment",
    -- })
  end)
