package webapi

import (
	core "opm.dev/core@v1"
	webapi ".."
)

// Default ModuleRelease for local testing
core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "webapi-app-test"
		namespace: "default"
		labels: {
			"environment": "test"
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

	// Concrete values for testing
	values: {
		web: {
			image:    "nginx:latest"
			replicas: 2
		}
		api: {
			image:    "myapp/api:v1.0.0"
			replicas: 3
		}
	}
}
