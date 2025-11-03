package examples

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// ModuleDefinition: Multi-tier Application Demonstrating New Traits
/////////////////////////////////////////////////////////////////

exampleNewTraitsModuleDefinition: core.#ModuleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/modules/core@v1"
		name:        "MultiTierApp"
		version:     "1.0.0"
		description: "Multi-tier application demonstrating new trait patterns"
	}

	#components: {
		// Stateful database component
		database: core.#ComponentDefinition & {
			metadata: name: "database"

			workload_units.#Container
			storage_units.#Volumes
			workload_traits.#Replicas
			workload_traits.#RestartPolicy
			workload_traits.#HealthCheck
		}

		// Daemon workload for logging
		logAgent: core.#ComponentDefinition & {
			metadata: name: "log-agent"

			workload_units.#Container
			workload_traits.#RestartPolicy
			workload_traits.#UpdateStrategy
			workload_traits.#HealthCheck
		}

		// One-time setup job
		setupJob: core.#ComponentDefinition & {
			metadata: name: "setup-job"

			workload_units.#Container
			workload_traits.#RestartPolicy
			workload_traits.#JobConfig
		}

		// Scheduled backup job
		backupJob: core.#ComponentDefinition & {
			metadata: name: "backup-job"

			workload_units.#Container
			workload_traits.#RestartPolicy
			workload_traits.#CronJobConfig
		}
	}

	// Value schema: Constraints only
	#values: {
		database: {
			image!:      string
			replicas?:   int & >=1 & <=5 | *1
			volumeSize!: string
		}
		logAgent: {
			image!: string
		}
		setupJob: {
			image!: string
		}
		backupJob: {
			image!:    string
			schedule!: string
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Module: Flattened Form with Concrete Spec
/////////////////////////////////////////////////////////////////

exampleNewTraitsModule: core.#Module & {
	metadata: {
		apiVersion:  "opm.dev/modules/core@v1"
		name:        "MultiTierApp"
		version:     "1.0.0"
		description: "Multi-tier application (flattened)"
	}

	#components: {
		database: {
			metadata: name: "database"

			workload_units.#Container
			storage_units.#Volumes
			workload_traits.#Replicas
			workload_traits.#RestartPolicy
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  #values.database.image
					image: "postgres:14"
					ports: {
						postgres: {
							name:       "postgres"
							targetPort: 5432
						}
					}
					env: {
						POSTGRES_DB: {
							name:  "POSTGRES_DB"
							value: "myapp"
						}
					}
					volumeMounts: {
						data: {
							name:      "data"
							mountPath: "/var/lib/postgresql/data"
						}
					}
				}

				volumes: data: {
					name: "data"
					persistentClaim: {
						size:       #values.database.volumeSize
						accessMode: "ReadWriteOnce"
					}
				}

				replicas: #values.database.replicas

				restartPolicy: "Always"

				healthCheck: {
					readinessProbe: {
						exec: {
							command: ["pg_isready"]
						}
						initialDelaySeconds: 5
						periodSeconds:       10
					}
				}
			}
		}

		logAgent: {
			metadata: name: "log-agent"

			workload_units.#Container
			workload_traits.#RestartPolicy
			workload_traits.#UpdateStrategy
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  #values.logAgent.image
					image: "fluent/fluent-bit:2.1"
					ports: {
						http: {
							name:       "http"
							targetPort: 2020
						}
					}
				}

				restartPolicy: "Always"

				updateStrategy: {
					type: "RollingUpdate"
					rollingUpdate: {
						maxUnavailable: 1
					}
				}

				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/"
							port: 2020
						}
						initialDelaySeconds: 15
						periodSeconds:       20
					}
				}
			}
		}

		setupJob: {
			metadata: name: "setup-job"

			workload_units.#Container
			workload_traits.#RestartPolicy
			workload_traits.#JobConfig

			spec: {
				container: {
					name:  #values.setupJob.image
					image: "myregistry.io/setup:v1"
				}

				restartPolicy: "OnFailure"

				jobConfig: {
					completions:             1
					parallelism:             1
					backoffLimit:            3
					activeDeadlineSeconds:   600
					ttlSecondsAfterFinished: 86400
				}
			}
		}

		backupJob: {
			metadata: name: "backup-job"

			workload_units.#Container
			workload_traits.#RestartPolicy
			workload_traits.#CronJobConfig

			spec: {
				container: {
					name:  #values.backupJob.image
					image: "postgres:14"
				}

				restartPolicy: "OnFailure"

				cronJobConfig: {
					scheduleCron:               #values.backupJob.schedule
					concurrencyPolicy:          "Forbid"
					successfulJobsHistoryLimit: 3
					failedJobsHistoryLimit:     1
				}
			}
		}
	}

	#values: {
		database: {
			image!:      string
			replicas?:   int & >=1 & <=5 | *1
			volumeSize!: string
		}
		logAgent: {
			image!: string
		}
		setupJob: {
			image!: string
		}
		backupJob: {
			image!:    string
			schedule!: string
		}
	}
}

/////////////////////////////////////////////////////////////////
//// ModuleRelease: Production Deployment
/////////////////////////////////////////////////////////////////

exampleNewTraitsModuleReleaseProduction: core.#ModuleRelease & {
	metadata: {
		name:      "multi-tier-production"
		namespace: "production"
		labels: {
			"environment": "production"
		}
	}

	module: exampleNewTraitsModule

	values: {
		database: {
			image:      "postgres:14"
			replicas:   3
			volumeSize: "100Gi"
		}
		logAgent: {
			image: "fluent/fluent-bit:2.1"
		}
		setupJob: {
			image: "myregistry.io/setup:v1.0.0"
		}
		backupJob: {
			image:    "postgres:14"
			schedule: "0 2 * * *"
		}
	}
}

/////////////////////////////////////////////////////////////////
//// ModuleRelease: Staging Deployment
/////////////////////////////////////////////////////////////////

exampleNewTraitsModuleReleaseStaging: core.#ModuleRelease & {
	metadata: {
		name:      "multi-tier-staging"
		namespace: "staging"
		labels: {
			"environment": "staging"
		}
	}

	module: exampleNewTraitsModule

	values: {
		database: {
			image:      "postgres:14"
			replicas:   1
			volumeSize: "20Gi"
		}
		logAgent: {
			image: "fluent/fluent-bit:2.1"
		}
		setupJob: {
			image: "myregistry.io/setup:v1.0.0"
		}
		backupJob: {
			image:    "postgres:14"
			schedule: "0 4 * * *"
		}
	}
}
