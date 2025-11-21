package database

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Stateful database module for testing StatefulSet
core.#ModuleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/modules/test@v1"
		name:        "database-app"
		version:     "1.0.0"
		description: "Test module with stateful PostgreSQL database"
		labels: {
			"type": "database"
			"env":  "test"
		}
	}

	#components: {
		postgres: {
			metadata: {
				name: "postgres-db"
				labels: {
					"tier":     "data"
					"database": "postgresql"
				}
			}

			// Container resource
			workload_resources.#Container
			// Restart policy trait
			workload_traits.#RestartPolicy

			spec: {
				container: {
					name:  metadata.name
					image: #values.postgres.image
					ports: {
						postgres: {
							name:       "postgres"
							targetPort: 5432
							protocol:   "TCP"
						}
					}
					env: {
						POSTGRES_USER:     "admin"
						POSTGRES_PASSWORD: "supersecret"
						POSTGRES_DB:       "appdb"
					}
				}
				restartPolicy: "Always"
			}
		}
	}

	// Value schema
	#values: {
		postgres: {
			image!: string
		}
	}
}
