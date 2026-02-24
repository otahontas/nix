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
			scale = 3,
			width = 1200,
			cli_args = { "-p", vim.fn.stdpath("config") .. "/puppeteer-config.json" },
		},
	},
})
