return {
	settings = {
		nixd = {
			formatting = {
				command = { "nixfmt" },
			},
			options = {
				["home-manager"] = {
					expr = '(builtins.getFlake "/Users/otahontas/.nix/home").homeConfigurations."otahontas".options',
				},
			},
		},
	},
}
