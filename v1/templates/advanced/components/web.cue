package components

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Web Component Definition

_web: core.#ComponentDefinition & {
	metadata: name: "web"

	// Compose resources and traits using helpers
	workload_resources.#Container
	workload_traits.#Replicas

	// Define concrete spec values
	spec: {
		container: {
			name:  "web-server"
			image: string
			ports: {
				http: {
					name:       "http"
					protocol:   "TCP"
					targetPort: 80
				}
			}
		}
		replicas: 3
	}
}
