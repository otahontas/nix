local configured = false
local markdown_integration
local mermaid_rendering_enabled = true

local function setup_diagram()
	if configured then
		return require("diagram")
	end

	if #vim.api.nvim_list_uis() == 0 then
		return nil
	end

	local image_ok, image_err = pcall(function()
		---@type any
		local image_config = {
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
		}

		require("image").setup(image_config)
	end)

	if not image_ok then
		vim.notify("image.nvim setup failed: " .. tostring(image_err), vim.log.levels.WARN, { title = "Diagram.nvim" })
		return nil
	end

	local diagram_ok, diagram_or_err = pcall(function()
		markdown_integration = require("diagram.integrations.markdown")
		local query_buffer_diagrams = markdown_integration.query_buffer_diagrams

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

		return diagram
	end)

	if not diagram_ok then
		vim.notify(
			"diagram.nvim setup failed: " .. tostring(diagram_or_err),
			vim.log.levels.WARN,
			{ title = "Diagram.nvim" }
		)
		return nil
	end

	configured = true
	return diagram_or_err
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = setup_diagram,
	desc = "Load markdown diagram rendering",
})

vim.keymap.set("n", "<leader>md", function()
	mermaid_rendering_enabled = not mermaid_rendering_enabled
	local diagram = setup_diagram()
	if diagram then
		diagram.render()
	end

	local state = mermaid_rendering_enabled and "enabled" or "disabled"
	vim.notify("Markdown mermaid rendering " .. state, vim.log.levels.INFO, { title = "Diagram.nvim" })
end, { desc = "Toggle mermaid rendering in markdown" })
