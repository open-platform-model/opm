package components

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Api Component Definition

_api: core.#ComponentDefinition & {
	metadata: name: "api"

	// Compose resources and traits using helpers
	workload_resources.#Container
	workload_traits.#Replicas

	// Define concrete spec values
	spec: {
		container: {
			name:  "api-server"
			image: string
			ports: {
				http: {
					name:       "http"
					protocol:   "TCP"
					targetPort: 8080
				}
			}
		}
		replicas: 2
	}
}
