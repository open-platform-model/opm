package moderate

import (
	core "opmodel.dev/core@v1"
	workload_resources "opmodel.dev/resources/workload@v1"
	workload_traits "opmodel.dev/traits/workload@v1"
	storage_resources "opmodel.dev/resources/storage@v1"
)

// Moderate 4-component web application with blueprints expanded
// This represents a Module where blueprints have been flattened into resources + traits
moderateModule: core.#Module & {
	metadata: {
		apiVersion:  "opmodel.dev/benchmarks/moderate@v0"
		name:        "ModerateWebApp"
		version:     "1.0.0"
		
	}

	#components: {
		frontend: core.#Component & {
			metadata: {
				name:        "web-frontend"
				
				labels: {
					"app.opmodel.dev/tier":      "frontend"
					"app.opmodel.dev/component": "ui"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + UpdateStrategyTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#UpdateStrategy

			spec: {
				container: {
					name:  "frontend"
					image: #values.frontend.image
					ports: {
						http: {
							name:       "http"
							targetPort: 3000
							protocol:   "TCP"
						}
					}
					env: {
						API_URL: {
							name:  "API_URL"
							value: #values.frontend.apiUrl
						}
						PUBLIC_URL: {
							name:  "PUBLIC_URL"
							value: #values.frontend.publicUrl
						}
					}
					resources: {
						requests: {
							cpu:    "100m"
							memory: "128Mi"
						}
						limits: {
							cpu:    "500m"
							memory: "512Mi"
						}
					}
				}
				replicas: #values.frontend.replicas
				updateStrategy: {
					type: "RollingUpdate"
					rollingUpdate: {
						maxUnavailable: 1
						maxSurge:       1
					}
				}
			}
		}

		api: core.#Component & {
			metadata: {
				name:        "api-backend"
				
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "api"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait + UpdateStrategyTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck
			workload_traits.#UpdateStrategy

			spec: {
				container: {
					name:  "api"
					image: #values.api.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8080
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8080"
						}
						NODE_ENV: {
							name:  "NODE_ENV"
							value: #values.api.environment
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.api.databaseUrl
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.api.redisUrl
						}
					}
					resources: {
						requests: {
							cpu:    "200m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "1Gi"
						}
					}
				}
				replicas: #values.api.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8080
						}
						initialDelaySeconds: 30
						periodSeconds:       10
						failureThreshold:    3
					}
					readinessProbe: {
						httpGet: {
							path: "/ready"
							port: 8080
						}
						initialDelaySeconds: 10
						periodSeconds:       5
						failureThreshold:    3
					}
				}
				updateStrategy: {
					type: "RollingUpdate"
					rollingUpdate: {
						maxUnavailable: 1
						maxSurge:       2
					}
				}
			}
		}

		database: core.#Component & {
			metadata: {
				name:        "postgres-database"
				
				labels: {
					"app.opmodel.dev/tier":      "data"
					"app.opmodel.dev/component": "database"
				}
			}

			// Blueprint expanded: StatefulWorkload → ContainerResource + VolumeResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			storage_resources.#Volumes
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "postgres"
					image: #values.database.image
					ports: {
						postgres: {
							name:       "postgres"
							targetPort: 5432
							protocol:   "TCP"
						}
					}
					env: {
						POSTGRES_DB: {
							name:  "POSTGRES_DB"
							value: #values.database.dbName
						}
						POSTGRES_USER: {
							name:  "POSTGRES_USER"
							value: #values.database.username
						}
						POSTGRES_PASSWORD: {
							name:  "POSTGRES_PASSWORD"
							value: #values.database.password
						}
						PGDATA: {
							name:  "PGDATA"
							value: "/var/lib/postgresql/data/pgdata"
						}
					}
					resources: {
						requests: {
							cpu:    "500m"
							memory: "1Gi"
						}
						limits: {
							cpu:    "2000m"
							memory: "4Gi"
						}
					}
					volumeMounts: {
						data: {
							name:      "pgdata"
							mountPath: "/var/lib/postgresql/data"
						}
					}
				}
				replicas: #values.database.replicas
				volumes: {
					pgdata: {
						name: "pgdata"
						persistentClaim: {
							size:         #values.database.volumeSize
							accessMode:   "ReadWriteOnce"
							storageClass: "standard"
						}
					}
				}
				healthCheck: {
					livenessProbe: {
						exec: {
							command: ["pg_isready", "-U", #values.database.username]
						}
						initialDelaySeconds: 30
						periodSeconds:       10
					}
					readinessProbe: {
						exec: {
							command: ["pg_isready", "-U", #values.database.username]
						}
						initialDelaySeconds: 5
						periodSeconds:       5
					}
				}
			}
		}

		worker: core.#Component & {
			metadata: {
				name:        "background-worker"
				
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "worker"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "worker"
					image: #values.worker.image
					env: {
						NODE_ENV: {
							name:  "NODE_ENV"
							value: #values.worker.environment
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.worker.databaseUrl
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.worker.redisUrl
						}
						WORKER_CONCURRENCY: {
							name:  "WORKER_CONCURRENCY"
							value: #values.worker.concurrency
						}
					}
					resources: {
						requests: {
							cpu:    "300m"
							memory: "512Mi"
						}
						limits: {
							cpu:    "1500m"
							memory: "2Gi"
						}
					}
				}
				replicas: #values.worker.replicas
				healthCheck: {
					livenessProbe: {
						exec: {
							command: ["node", "healthcheck.js"]
						}
						initialDelaySeconds: 60
						periodSeconds:       30
					}
				}
			}
		}
	}

	#values: {
		frontend: {
			image!:     string
			apiUrl!:    string
			publicUrl!: string
			replicas?:  int & >=1 & <=10 | *2
		}
		api: {
			image!:       string
			environment!: "development" | "staging" | "production"
			databaseUrl!: string
			redisUrl!:    string
			replicas?:    int & >=1 & <=20 | *3
		}
		database: {
			image!:      string
			dbName!:     string
			username!:   string
			password!:   string
			volumeSize!: string
			replicas?:   int & >=1 & <=3 | *1
		}
		worker: {
			image!:       string
			environment!: "development" | "staging" | "production"
			databaseUrl!: string
			redisUrl!:    string
			concurrency!: string
			replicas?:    int & >=1 & <=10 | *2
		}
	}
}
