require("utils").add_package({
  {
    src = "https://github.com/Saghen/blink.cmp",
    version = "v1.7.0",
  },
  "https://github.com/rafamadriz/friendly-snippets",
}, function()
  require("blink.cmp").setup({
    completion = { documentation = { auto_show = true, }, },
    signature = { enabled = true, },
  })
end)
