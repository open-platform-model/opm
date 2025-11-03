package examples

import (
	core "opm.dev/core@v1"
	workload_blueprints "opm.dev/blueprints/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// ScheduledTaskWorkload Blueprint Example - Database Backup
//// Demonstrates cron job configuration
/////////////////////////////////////////////////////////////////

exampleScheduledTaskWorkload: core.#ComponentDefinition & {
	metadata: {
		name: "database-backup-cronjob"
	}

	// Use the ScheduledTaskWorkload blueprint
	workload_blueprints.#ScheduledTaskWorkload

	spec: {
		scheduledTaskWorkload: {
			container: {
				name:  "backup"
				image: "postgres:14"
				env: {
					PGHOST: {
						name:  "PGHOST"
						value: "postgres-service"
					}
					PGUSER: {
						name:  "PGUSER"
						value: "admin"
					}
					PGPASSWORD: {
						name:  "PGPASSWORD"
						value: "secretpassword"
					}
					BACKUP_LOCATION: {
						name:  "BACKUP_LOCATION"
						value: "/backups"
					}
				}
				resources: {
					requests: {
						cpu:    "250m"
						memory: "256Mi"
					}
					limits: {
						cpu:    "500m"
						memory: "512Mi"
					}
				}
				volumeMounts: {
					backups: {
						name:      "backup-storage"
						mountPath: "/backups"
					}
				}
			}

			restartPolicy: "OnFailure"

			cronJobConfig: {
				scheduleCron:               "0 2 * * *"
				concurrencyPolicy:          "Forbid"
				startingDeadlineSeconds:    300
				successfulJobsHistoryLimit: 3
				failedJobsHistoryLimit:     1
			}

			initContainers: [{
				name:  "pre-backup-check"
				image: "postgres:14"
				env: {
					PGHOST: {
						name:  "PGHOST"
						value: "postgres-service"
					}
				}
			}]
		}

		// Route blueprint spec to unit/trait specs
		container:      scheduledTaskWorkload.container
		restartPolicy:  scheduledTaskWorkload.restartPolicy
		cronJobConfig:  scheduledTaskWorkload.cronJobConfig
		initContainers: scheduledTaskWorkload.initContainers
	}
}
