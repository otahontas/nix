return {
  init_options = {
    documentFormatting = true,
  },
  filetypes = { "nu", },
  settings = {
    languages = {
      nu = {
        {
          formatCommand = "topiary-nushell format --language nu",
          formatStdin = true,
        },
      },
    },
  },
}
