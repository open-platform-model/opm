package nocomponents

import (
	core "opm.dev/core@v1"
	nocomponents ".."
)

core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "empty-module-test"
		namespace: "default"
	}

	module: {
		apiVersion:  nocomponents.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    nocomponents.metadata
		#components: nocomponents.#components
		#values:     nocomponents.#values
	}

	values: {}
}
