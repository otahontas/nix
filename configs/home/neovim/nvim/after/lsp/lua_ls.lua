return {
  settings = {
    Lua = {
      -- Define runtime properties. Use 'LuaJIT', as it is built into Neovim.
      runtime = { version = "LuaJIT", path = vim.split(package.path, ";"), },
      workspace = {
        -- Don't analyze code from submodules
        ignoreSubmodules = true,
        -- Add Neovim's methods for easier code writing
        library = { vim.env.VIMRUNTIME, },
      },
      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
          max_line_length = "88",
          quote_style = "double",
          trailing_table_separator = "always",
          table_separator_style = "comma",
          continuation_indent = "2",
          call_arg_parentheses = "keep",
          space_before_function_open_parenthesis = "true",
        },
      },
      -- Enable inlay hints
      hint = {
        enable = true,
      },
    },
  },
}
