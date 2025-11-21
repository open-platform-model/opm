package nomatch

import (
	core "opm.dev/core@v1"
	nomatch ".."
)

core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "no-transformer-test"
		namespace: "default"
	}

	module: {
		apiVersion:  nomatch.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    nomatch.metadata
		#components: nomatch.#components
		#values:     nomatch.#values
	}

	values: {}
}
