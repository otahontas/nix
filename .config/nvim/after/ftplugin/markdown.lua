local utils = require("utils")
utils.disable_hard_wrap_for_buffer(0)

-- Spellcheck for markdown files
vim.opt_local.spell = true

-- Set wrap
vim.opt_local.wrap = true

-- Markdown-specific surrounding in 'mini.surround'
vim.b.minisurround_config = {
  custom_surroundings = {
    -- Markdown link. Common usage:
    -- `saiwL` + [type/paste link] + <CR> - add link
    -- `sdL` - delete link
    -- `srLL` + [type/paste link] + <CR> - replace link
    L = {
      input = { "%[().-()%]%(.-%)", },
      output = function()
        local link = require("mini.surround").user_input("Link: ")
        return { left = "[", right = "](" .. link .. ")", }
      end,
    },
  },
}
