require("image").setup({
	backend = "kitty",
	processor = "magick_cli",
	integrations = {
		markdown = {
			enabled = true,
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

local markdown_integration = require("diagram.integrations.markdown")
local query_buffer_diagrams = markdown_integration.query_buffer_diagrams
local mermaid_rendering_enabled = true

markdown_integration.query_buffer_diagrams = function(bufnr)
	local diagrams = query_buffer_diagrams(bufnr)
	if mermaid_rendering_enabled then
		return diagrams
	end

	return vim.tbl_filter(function(diagram)
		return diagram.renderer_id ~= "mermaid"
	end, diagrams)
end

local diagram = require("diagram")
diagram.setup({
	integrations = {
		markdown_integration,
	},
	renderer_options = {
		mermaid = {
			scale = 3,
			width = 1200,
			cli_args = { "-p", vim.fn.stdpath("config") .. "/puppeteer-config.json" },
		},
	},
})

vim.keymap.set("n", "<leader>md", function()
	mermaid_rendering_enabled = not mermaid_rendering_enabled
	diagram.render()

	local state = mermaid_rendering_enabled and "enabled" or "disabled"
	vim.notify("Markdown mermaid rendering " .. state, vim.log.levels.INFO, { title = "Diagram.nvim" })
end, { desc = "Toggle mermaid rendering in markdown" })
