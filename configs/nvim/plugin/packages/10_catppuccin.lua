require("utils").add_package(
  { { src = "https://github.com/catppuccin/nvim", name = "catppuccin", }, },
  function()
    require("catppuccin").setup({
      flavour = "latte", -- latte, frappe, macchiato, mocha
    })
    vim.cmd("colorscheme catppuccin")
  end
)
