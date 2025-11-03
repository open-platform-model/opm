package examples

import (
	core "opm.dev/core@v1"
	data_blueprints "opm.dev/blueprints/data@v1"
)

/////////////////////////////////////////////////////////////////
//// SimpleDatabase Blueprint Example - PostgreSQL
//// Alternative database example
/////////////////////////////////////////////////////////////////

exampleSimpleDatabasePostgres: core.#ComponentDefinition & {
	metadata: {
		name: "postgres-simple"
	}

	// Use the SimpleDatabase blueprint
	data_blueprints.#SimpleDatabase

	spec: {
		simpleDatabase: {
			engine:   "postgres"
			version:  "14"
			dbName:   "myapp"
			username: "admin"
			password: "postgrespassword"
			persistence: {
				enabled: true
				size:    "100Gi"
			}
		}
	}
}
