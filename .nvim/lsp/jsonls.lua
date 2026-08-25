local schemastore = require("schemastore")

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#JSON diagnostics]]
return {
	cmd = { "vscode-json-languageserver", "--stdio" },
	settings = {
		json = {
			schemas = schemastore.json.schemas(),
			validate = { enable = true },
		},
	},
}
