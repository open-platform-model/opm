package components

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Api Component Definition

_api: core.#ComponentDefinition & {
	metadata: name: "api"

	// Compose units and traits using helpers
	workload_units.#Container
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
