return {
  settings = {
    nixd = {
      formatting = {
        command = { "nixfmt", },
      },
      options = {
        ["home-manager"] = {
          expr =
          '(builtins.getFlake "/Users/otahontas/.config/nix-darwin").darwinConfigurations."otabook-work".options.home-manager.users.type.getSubOptions []',
        },
      },
    },
  },
}
