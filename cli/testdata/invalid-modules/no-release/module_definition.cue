package norelease

import core "opm.dev/core@v1"

// Valid module but no release file exists
core.#ModuleDefinition & {
	metadata: {
		apiVersion: "opm.dev/modules/test@v1"
		name:       "no-release-module"
		version:    "1.0.0"
	}

	#components: {
		test: {
			metadata: name: "test-component"
			#resources: {}
		}
	}

	#values: {}
}
