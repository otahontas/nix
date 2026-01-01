require("utils").add_package(
  {
    {
      src = "https://github.com/catppuccin/nvim",
      name = "catppuccin",
    },
  },
  function()
    require("catppuccin").setup({
      integrations = {
        mini = {
          enabled = true,
          indentscope_color = "mocha",
        },
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end)
