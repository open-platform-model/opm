package nocomponents

import core "opm.dev/core@v1"

// Module with no components - should fail rendering
core.#ModuleDefinition & {
	metadata: {
		apiVersion: "opm.dev/modules/test@v1"
		name:       "empty-module"
		version:    "1.0.0"
	}

	// Empty components
	#components: {}

	#values: {}
}
