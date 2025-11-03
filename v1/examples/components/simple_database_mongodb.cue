package examples

import (
	core "opm.dev/core@v1"
	data_blueprints "opm.dev/blueprints/data@v1"
)

/////////////////////////////////////////////////////////////////
//// SimpleDatabase Blueprint Example - MongoDB
//// Demonstrates database deployment with persistent storage
/////////////////////////////////////////////////////////////////

exampleSimpleDatabase: core.#ComponentDefinition & {
	metadata: {
		name: "mongodb-simple"
	}

	// Use the SimpleDatabase blueprint
	data_blueprints.#SimpleDatabase

	spec: {
		simpleDatabase: {
			engine:   "mongodb"
			version:  "6.0"
			dbName:   "myapp"
			username: "admin"
			password: "mongopassword"
			persistence: {
				enabled:      true
				size:         "50Gi"
				storageClass: "fast-ssd"
			}
		}
	}
}
