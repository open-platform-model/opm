package examples

import (
	core "opm.dev/core@v1"
	data_blueprints "opm.dev/blueprints/data@v1"
)

/////////////////////////////////////////////////////////////////
//// SimpleDatabase Blueprint Example - Redis
//// In-memory cache without persistence
/////////////////////////////////////////////////////////////////

exampleSimpleDatabaseRedis: core.#ComponentDefinition & {
	metadata: {
		name: "redis-cache"
	}

	// Use the SimpleDatabase blueprint
	data_blueprints.#SimpleDatabase

	spec: {
		simpleDatabase: {
			engine:   "redis"
			version:  "7.0"
			dbName:   "redis"
			username: "default"
			password: ""
			persistence: {
				enabled: false
			}
		}
	}
}
