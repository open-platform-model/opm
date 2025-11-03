package components

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Worker Component Definition

_worker: core.#ComponentDefinition & {
	metadata: name: "worker"

	// Compose units and traits using helpers
	workload_units.#Container
	workload_traits.#Replicas

	// Define concrete spec values
	spec: {
		container: {
			name:  "background-worker"
			image: string
		}
		replicas: 2
	}
}
