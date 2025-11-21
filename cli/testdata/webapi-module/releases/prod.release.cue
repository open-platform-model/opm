package webapi

import (
	core "opm.dev/core@v1"
	webapi ".."
)

// Production ModuleRelease with higher replicas
core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "webapi-app-production"
		namespace: "production"
		labels: {
			"environment": "production"
			"team":        "platform"
		}
	}

	// Embed the module definition
	module: {
		apiVersion:  webapi.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    webapi.metadata
		#components: webapi.#components
		#values:     webapi.#values
	}

	// Production values with higher replicas
	values: {
		web: {
			image:    "nginx:1.25"
			replicas: 5
		}
		api: {
			image:    "myapp/api:v2.1.0"
			replicas: 8
		}
	}
}
