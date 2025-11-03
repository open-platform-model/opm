package components

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Web Component Definition

_web: core.#ComponentDefinition & {
	metadata: name: "web"

	// Compose units and traits using helpers
	workload_units.#Container
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
