require("utils").add_package(
  { { src = "https://github.com/rose-pine/neovim", name = "rose-pine", }, },
  function()
    require("rose-pine").setup({
      variant = "dawn", -- auto, main, moon, or dawn
    })
    vim.cmd("colorscheme rose-pine")
  end
)
