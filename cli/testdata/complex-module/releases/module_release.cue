package complex

import (
	core "opm.dev/core@v1"
	complex ".."
)

// Default ModuleRelease for complex testing
core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "complex-app-test"
		namespace: "default"
		labels: {
			"environment": "test"
		}
	}

	// Embed the module definition
	module: {
		apiVersion:  complex.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    complex.metadata
		#components: complex.#components
		#values:     complex.#values
	}

	// Concrete values for testing
	values: {
		frontend: {
			image:    "nginx:latest"
			replicas: 2
		}
		backend: {
			image:    "myapp/backend:v1.0.0"
			replicas: 3
		}
		cache: {
			image: "redis:7-alpine"
		}
		worker: {
			image: "myapp/worker:v1.0.0"
		}
	}
}
