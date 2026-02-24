return {
	settings = {
		nixd = {
			options = {
				["home-manager"] = {
					expr = '(builtins.getFlake "/Users/otahontas/.nix/home").homeConfigurations."otahontas".options',
				},
			},
		},
	},
}
