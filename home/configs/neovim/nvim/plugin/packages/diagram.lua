require("image").setup({
	backend = "kitty",
	processor = "magick_cli",
	integrations = {
		markdown = {
			enabled = false,
		},
		neorg = {
			enabled = false,
		},
		typst = {
			enabled = false,
		},
		html = {
			enabled = false,
		},
		css = {
			enabled = false,
		},
	},
})

require("diagram").setup({
	integrations = {
		require("diagram.integrations.markdown"),
	},
	renderer_options = {
		mermaid = {
			cli_args = { "--no-sandbox" },
		},
	},
})
