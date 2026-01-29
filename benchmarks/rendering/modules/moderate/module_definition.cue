package moderate

import (
	workload_blueprints "opmodel.dev/blueprints/workload@v1"
)

// Moderate 4-component web application using blueprints
// This represents a ModuleDefinition where components reference blueprints
moderateModuleDefinition: {
	apiVersion: "opmodel.dev/v1/core"
	kind:       "ModuleDefinition"

	metadata: {
		apiVersion:  "opmodel.dev/benchmarks/moderate@v0"
		name:        "ModerateWebApp"
		version:     "1.0.0"
		
	}

	#components: {
		frontend: {
			metadata: {
				name:        "web-frontend"
				
				labels: {
					"app.opmodel.dev/tier":      "frontend"
					"app.opmodel.dev/component": "ui"
				}
			}

			// Blueprints
			workload_blueprints.#StatelessWorkload

			spec: statelessWorkload: {
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

		api: {
			metadata: {
				name:        "api-backend"
				
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "api"
				}
			}

			// Blueprints
			workload_blueprints.#StatelessWorkload

			spec: statelessWorkload: {
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

		database: {
			workload_blueprints.#StatefulWorkload
			metadata: {
				name:        "postgres-database"
				
				labels: {
					"app.opmodel.dev/tier":      "data"
					"app.opmodel.dev/component": "database"
				}
			}

			// Blueprints
			workload_blueprints.#StatefulWorkload

			spec: statefulWorkload: {
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

		worker: {
			metadata: {
				name:        "background-worker"
				
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "worker"
				}
			}

			// Blueprints
			workload_blueprints.#StatelessWorkload

			spec: statelessWorkload: {
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
