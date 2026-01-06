require("utils").add_package({ "https://github.com/dmmulroy/ts-error-translator.nvim", },
  function()
    require("ts-error-translator").setup({})
  end
)
