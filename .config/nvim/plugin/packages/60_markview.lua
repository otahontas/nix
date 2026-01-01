require("utils").add_package({ "https://github.com/OXY2DEV/markview.nvim", },
  function()
    require("markview").setup({
      preview = {
        icon_provider = "mini",
      },
    })
  end)

-- Fix the navigating annoyance: when jumping with 5e, I can not see where I jumped to
