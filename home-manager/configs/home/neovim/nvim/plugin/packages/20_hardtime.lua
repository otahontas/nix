require("utils").add_package({ "https://github.com/m4xshen/hardtime.nvim", },
  function()
    require("hardtime").setup({
      max_time = 2000,
      max_count = 2,
      disable_mouse = false,
    })
  end
)
