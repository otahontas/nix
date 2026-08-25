local schemastore = require("schemastore")

local devenvYamlSchema = {
	description = "devenv project configuration",
	fileMatch = { "devenv.yaml", "**/devenv.yaml" },
	name = "devenv.yaml",
	url = "https://devenv.sh/devenv.schema.json",
}

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
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = schemastore.yaml.schemas({
				extra = { devenvYamlSchema },
			}),
		},
	},
}
