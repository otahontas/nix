require("copilot").setup({
	panel = {
		enabled = false,
	},
	suggestion = {
		auto_trigger = true,
	},
	server_opts_overrides = {
		settings = {
			telemetry = {
				telemetryLevel = "off",
			},
		},
	},
})
