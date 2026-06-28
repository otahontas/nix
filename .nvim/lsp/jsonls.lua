local jsonSchemas = nil
local has_schemastore, schemastore = pcall(require, "schemastore")

if has_schemastore then
	jsonSchemas = schemastore.json.schemas()
end

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#JSON diagnostics]]
return {
	cmd = { "vscode-json-languageserver", "--stdio" },
	settings = {
		json = {
			schemas = jsonSchemas,
			validate = { enable = true },
		},
	},
}
