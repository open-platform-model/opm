package database

import (
	core "opm.dev/core@v1"
	database ".."
)

// Default ModuleRelease for database testing
core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "database-app-test"
		namespace: "default"
		labels: {
			"environment": "test"
		}
	}

	// Embed the module definition
	module: {
		apiVersion:  database.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    database.metadata
		#components: database.#components
		#values:     database.#values
	}

	// Concrete values for testing
	values: {
		postgres: {
			image: "postgres:14"
		}
	}
}
