package examples

import (
	core "opm.dev/core@v1"
	workload_blueprints "opm.dev/blueprints/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// TaskWorkload Blueprint Example - Data Migration Job
//// Demonstrates one-time job configuration
/////////////////////////////////////////////////////////////////

exampleTaskWorkload: core.#ComponentDefinition & {
	metadata: {
		name: "data-migration-job"
	}

	// Use the TaskWorkload blueprint
	workload_blueprints.#TaskWorkload

	spec: {
		taskWorkload: {
			container: {
				name:  "migration"
				image: "myregistry.io/migrations:v2.0.0"
				env: {
					DATABASE_URL: {
						name:  "DATABASE_URL"
						value: "postgres://localhost:5432/myapp"
					}
					MIGRATION_VERSION: {
						name:  "MIGRATION_VERSION"
						value: "v2.0.0"
					}
				}
				resources: {
					requests: {
						cpu:    "500m"
						memory: "512Mi"
					}
					limits: {
						cpu:    "1000m"
						memory: "1Gi"
					}
				}
			}

			restartPolicy: "OnFailure"

			jobConfig: {
				completions:             1
				parallelism:             1
				backoffLimit:            3
				activeDeadlineSeconds:   3600
				ttlSecondsAfterFinished: 86400
			}

			initContainers: [{
				name:  "pre-migration-check"
				image: "myregistry.io/migrations:v2.0.0"
				env: {
					CHECK_MODE: {
						name:  "CHECK_MODE"
						value: "true"
					}
				}
			}]
		}

		// Route blueprint spec to unit/trait specs
		container:      taskWorkload.container
		restartPolicy:  taskWorkload.restartPolicy
		jobConfig:      taskWorkload.jobConfig
		initContainers: taskWorkload.initContainers
	}
}
