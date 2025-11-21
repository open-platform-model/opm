package nomatch

import core "opm.dev/core@v1"

// Module with component that has no matching transformer
core.#ModuleDefinition & {
	metadata: {
		apiVersion: "opm.dev/modules/test@v1"
		name:       "no-transformer-module"
		version:    "1.0.0"
	}

	#components: {
		unsupported: {
			metadata: name: "unsupported-component"

			// Component with no resources - transformers require specific resources
			#resources: {}

			spec: {
				// Custom field that no transformer knows about
				customUnsupportedField: "value"
			}
		}
	}

	#values: {}
}
