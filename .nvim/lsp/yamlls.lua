local has_schemastore, schemastore = pcall(require, "schemastore")

local devenvYamlSchema = {
	description = "devenv project configuration",
	fileMatch = { "devenv.yaml", "**/devenv.yaml" },
	name = "devenv.yaml",
	url = "https://devenv.sh/devenv.schema.json",
}

local yamlSchemas = {
	[devenvYamlSchema.url] = devenvYamlSchema.fileMatch,
}

if has_schemastore then
	yamlSchemas = schemastore.yaml.schemas({
		extra = { devenvYamlSchema },
	})
end

-- @lat: [[architecture#Architecture#Root devenv setup#Root language tooling#Config schema diagnostics]]
return {
	filetypes = {
		"yaml",
		"yaml.docker-compose",
		"yaml.github-action",
		"yaml.gitlab",
		"yaml.helm-values",
	},
	settings = {
		yaml = {
			schemaStore = has_schemastore and {
				enable = false,
				url = "",
			} or nil,
			schemas = yamlSchemas,
		},
	},
}
