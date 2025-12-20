return {
  settings = {
    emmylua = {
      runtime = {
        version = "LuaJIT",
      },
      workspace = {
        library = { vim.env.VIMRUNTIME, },
      },
      hint = {
        paramHint = true,
        localHint = true,
        overrideHint = true,
      },
    },
  },
}
