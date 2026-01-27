package large

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
	storage_resources "opm.dev/resources/storage@v1"
)

// Large 12-component e-commerce platform with blueprints expanded
// This represents a Module where blueprints have been flattened into resources + traits
largeModule: core.#Module & {
	metadata: {
		apiVersion:       "opm.dev/benchmarks/large@v0"
		name:             "ECommercePlatform"
		version:          "1.0.0"
		description:      "Complete e-commerce platform with microservices architecture (compiled/flattened)"
		defaultNamespace: ""
	}

	#components: {
		// 1. Frontend - React SPA
		frontend: core.#Component & {
			metadata: {
				name: "web-frontend"
				labels: {
					"app.opm.dev/tier":      "frontend"
					"app.opm.dev/component": "ui"
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
						API_GATEWAY_URL: {
							name:  "API_GATEWAY_URL"
							value: #values.frontend.apiGatewayUrl
						}
						PUBLIC_URL: {
							name:  "PUBLIC_URL"
							value: #values.frontend.publicUrl
						}
					}
					resources: {
						requests: {
							cpu:    "100m"
							memory: "256Mi"
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
						maxSurge:       2
					}
				}
			}
		}

		// 2. API Gateway
		apiGateway: core.#Component & {
			metadata: {
				name: "api-gateway"
				labels: {
					"app.opm.dev/tier":      "gateway"
					"app.opm.dev/component": "api-gateway"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "api-gateway"
					image: #values.apiGateway.image
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
						AUTH_SERVICE_URL: {
							name:  "AUTH_SERVICE_URL"
							value: #values.apiGateway.authServiceUrl
						}
						USER_SERVICE_URL: {
							name:  "USER_SERVICE_URL"
							value: #values.apiGateway.userServiceUrl
						}
						PRODUCT_SERVICE_URL: {
							name:  "PRODUCT_SERVICE_URL"
							value: #values.apiGateway.productServiceUrl
						}
						ORDER_SERVICE_URL: {
							name:  "ORDER_SERVICE_URL"
							value: #values.apiGateway.orderServiceUrl
						}
					}
					resources: {
						requests: {
							cpu:    "200m"
							memory: "512Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "1Gi"
						}
					}
				}
				replicas: #values.apiGateway.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8080
						}
						initialDelaySeconds: 30
						periodSeconds:       10
					}
					readinessProbe: {
						httpGet: {
							path: "/ready"
							port: 8080
						}
						initialDelaySeconds: 10
						periodSeconds:       5
					}
				}
			}
		}

		// 3. Auth Service
		authService: core.#Component & {
			metadata: {
				name: "auth-service"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "auth"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "auth-service"
					image: #values.authService.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8081
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8081"
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.authService.databaseUrl
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.authService.redisUrl
						}
						JWT_SECRET: {
							name:  "JWT_SECRET"
							value: #values.authService.jwtSecret
						}
					}
					resources: {
						requests: {
							cpu:    "150m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "750m"
							memory: "512Mi"
						}
					}
				}
				replicas: #values.authService.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8081
						}
						initialDelaySeconds: 20
						periodSeconds:       10
					}
				}
			}
		}

		// 4. User Service
		userService: core.#Component & {
			metadata: {
				name: "user-service"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "user"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "user-service"
					image: #values.userService.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8082
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8082"
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.userService.databaseUrl
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.userService.redisUrl
						}
					}
					resources: {
						requests: {
							cpu:    "150m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "750m"
							memory: "512Mi"
						}
					}
				}
				replicas: #values.userService.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8082
						}
						initialDelaySeconds: 20
						periodSeconds:       10
					}
				}
			}
		}

		// 5. Product Service
		productService: core.#Component & {
			metadata: {
				name: "product-service"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "product"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "product-service"
					image: #values.productService.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8083
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8083"
						}
						MONGODB_URL: {
							name:  "MONGODB_URL"
							value: #values.productService.mongodbUrl
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.productService.redisUrl
						}
					}
					resources: {
						requests: {
							cpu:    "200m"
							memory: "384Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "768Mi"
						}
					}
				}
				replicas: #values.productService.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8083
						}
						initialDelaySeconds: 25
						periodSeconds:       10
					}
				}
			}
		}

		// 6. Order Service
		orderService: core.#Component & {
			metadata: {
				name: "order-service"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "order"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "order-service"
					image: #values.orderService.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8084
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8084"
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.orderService.databaseUrl
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.orderService.redisUrl
						}
						PAYMENT_SERVICE_URL: {
							name:  "PAYMENT_SERVICE_URL"
							value: #values.orderService.paymentServiceUrl
						}
					}
					resources: {
						requests: {
							cpu:    "200m"
							memory: "384Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "768Mi"
						}
					}
				}
				replicas: #values.orderService.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8084
						}
						initialDelaySeconds: 25
						periodSeconds:       10
					}
				}
			}
		}

		// 7. Payment Service
		paymentService: core.#Component & {
			metadata: {
				name: "payment-service"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "payment"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "payment-service"
					image: #values.paymentService.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8085
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8085"
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.paymentService.databaseUrl
						}
						STRIPE_API_KEY: {
							name:  "STRIPE_API_KEY"
							value: #values.paymentService.stripeApiKey
						}
					}
					resources: {
						requests: {
							cpu:    "150m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "750m"
							memory: "512Mi"
						}
					}
				}
				replicas: #values.paymentService.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8085
						}
						initialDelaySeconds: 20
						periodSeconds:       10
					}
				}
			}
		}

		// 8. Notification Service
		notificationService: core.#Component & {
			metadata: {
				name: "notification-service"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "notification"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "notification-service"
					image: #values.notificationService.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8086
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8086"
						}
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.notificationService.redisUrl
						}
						SENDGRID_API_KEY: {
							name:  "SENDGRID_API_KEY"
							value: #values.notificationService.sendgridApiKey
						}
						TWILIO_API_KEY: {
							name:  "TWILIO_API_KEY"
							value: #values.notificationService.twilioApiKey
						}
					}
					resources: {
						requests: {
							cpu:    "100m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "500m"
							memory: "512Mi"
						}
					}
				}
				replicas: #values.notificationService.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8086
						}
						initialDelaySeconds: 20
						periodSeconds:       10
					}
				}
			}
		}

		// 9. PostgreSQL Database
		postgresDatabase: core.#Component & {
			metadata: {
				name: "postgres-database"
				labels: {
					"app.opm.dev/tier":      "data"
					"app.opm.dev/component": "database"
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
					image: #values.postgresDatabase.image
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
							value: #values.postgresDatabase.dbName
						}
						POSTGRES_USER: {
							name:  "POSTGRES_USER"
							value: #values.postgresDatabase.username
						}
						POSTGRES_PASSWORD: {
							name:  "POSTGRES_PASSWORD"
							value: #values.postgresDatabase.password
						}
						PGDATA: {
							name:  "PGDATA"
							value: "/var/lib/postgresql/data/pgdata"
						}
					}
					resources: {
						requests: {
							cpu:    "500m"
							memory: "2Gi"
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
				replicas: #values.postgresDatabase.replicas
				volumes: {
					pgdata: {
						name: "pgdata"
						persistentClaim: {
							size:         #values.postgresDatabase.volumeSize
							accessMode:   "ReadWriteOnce"
							storageClass: "standard"
						}
					}
				}
				healthCheck: {
					livenessProbe: {
						exec: {
							command: ["pg_isready", "-U", #values.postgresDatabase.username]
						}
						initialDelaySeconds: 30
						periodSeconds:       10
					}
				}
			}
		}

		// 10. Redis Cache
		redisCache: core.#Component & {
			metadata: {
				name: "redis-cache"
				labels: {
					"app.opm.dev/tier":      "data"
					"app.opm.dev/component": "cache"
				}
			}

			// Blueprint expanded: StatefulWorkload → ContainerResource + VolumeResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			storage_resources.#Volumes
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "redis"
					image: #values.redisCache.image
					ports: {
						redis: {
							name:       "redis"
							targetPort: 6379
							protocol:   "TCP"
						}
					}
					resources: {
						requests: {
							cpu:    "250m"
							memory: "512Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "2Gi"
						}
					}
					volumeMounts: {
						data: {
							name:      "redis-data"
							mountPath: "/data"
						}
					}
				}
				replicas: #values.redisCache.replicas
				volumes: {
					"redis-data": {
						name: "redis-data"
						persistentClaim: {
							size:         #values.redisCache.volumeSize
							accessMode:   "ReadWriteOnce"
							storageClass: "standard"
						}
					}
				}
				healthCheck: {
					livenessProbe: {
						exec: {
							command: ["redis-cli", "ping"]
						}
						initialDelaySeconds: 15
						periodSeconds:       5
					}
				}
			}
		}

		// 11. MongoDB (Product Catalog)
		mongoDatabase: core.#Component & {
			metadata: {
				name: "mongodb-database"
				labels: {
					"app.opm.dev/tier":      "data"
					"app.opm.dev/component": "nosql-database"
				}
			}

			// Blueprint expanded: StatefulWorkload → ContainerResource + VolumeResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			storage_resources.#Volumes
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "mongodb"
					image: #values.mongoDatabase.image
					ports: {
						mongo: {
							name:       "mongo"
							targetPort: 27017
							protocol:   "TCP"
						}
					}
					env: {
						MONGO_INITDB_ROOT_USERNAME: {
							name:  "MONGO_INITDB_ROOT_USERNAME"
							value: #values.mongoDatabase.username
						}
						MONGO_INITDB_ROOT_PASSWORD: {
							name:  "MONGO_INITDB_ROOT_PASSWORD"
							value: #values.mongoDatabase.password
						}
						MONGO_INITDB_DATABASE: {
							name:  "MONGO_INITDB_DATABASE"
							value: #values.mongoDatabase.dbName
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
							name:      "mongo-data"
							mountPath: "/data/db"
						}
					}
				}
				replicas: #values.mongoDatabase.replicas
				volumes: {
					"mongo-data": {
						name: "mongo-data"
						persistentClaim: {
							size:         #values.mongoDatabase.volumeSize
							accessMode:   "ReadWriteOnce"
							storageClass: "standard"
						}
					}
				}
				healthCheck: {
					livenessProbe: {
						exec: {
							command: ["mongosh", "--eval", "db.adminCommand('ping')"]
						}
						initialDelaySeconds: 30
						periodSeconds:       10
					}
				}
			}
		}

		// 12. Message Queue Worker
		messageQueueWorker: core.#Component & {
			metadata: {
				name: "mq-worker"
				labels: {
					"app.opm.dev/tier":      "backend"
					"app.opm.dev/component": "worker"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "worker"
					image: #values.messageQueueWorker.image
					env: {
						REDIS_URL: {
							name:  "REDIS_URL"
							value: #values.messageQueueWorker.redisUrl
						}
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: #values.messageQueueWorker.databaseUrl
						}
						WORKER_CONCURRENCY: {
							name:  "WORKER_CONCURRENCY"
							value: #values.messageQueueWorker.concurrency
						}
						NOTIFICATION_SERVICE_URL: {
							name:  "NOTIFICATION_SERVICE_URL"
							value: #values.messageQueueWorker.notificationServiceUrl
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
				replicas: #values.messageQueueWorker.replicas
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
			image!:          string
			apiGatewayUrl!:  string
			publicUrl!:      string
			replicas?:       int & >=1 & <=10 | *3
		}
		apiGateway: {
			image!:             string
			authServiceUrl!:    string
			userServiceUrl!:    string
			productServiceUrl!: string
			orderServiceUrl!:   string
			replicas?:          int & >=1 & <=10 | *3
		}
		authService: {
			image!:       string
			databaseUrl!: string
			redisUrl!:    string
			jwtSecret!:   string
			replicas?:    int & >=1 & <=10 | *2
		}
		userService: {
			image!:       string
			databaseUrl!: string
			redisUrl!:    string
			replicas?:    int & >=1 & <=10 | *2
		}
		productService: {
			image!:      string
			mongodbUrl!: string
			redisUrl!:   string
			replicas?:   int & >=1 & <=10 | *3
		}
		orderService: {
			image!:              string
			databaseUrl!:        string
			redisUrl!:           string
			paymentServiceUrl!:  string
			replicas?:           int & >=1 & <=10 | *2
		}
		paymentService: {
			image!:        string
			databaseUrl!:  string
			stripeApiKey!: string
			replicas?:     int & >=1 & <=10 | *2
		}
		notificationService: {
			image!:          string
			redisUrl!:       string
			sendgridApiKey!: string
			twilioApiKey!:   string
			replicas?:       int & >=1 & <=10 | *2
		}
		postgresDatabase: {
			image!:      string
			dbName!:     string
			username!:   string
			password!:   string
			volumeSize!: string
			replicas?:   int & >=1 & <=3 | *1
		}
		redisCache: {
			image!:      string
			volumeSize!: string
			replicas?:   int & >=1 & <=3 | *1
		}
		mongoDatabase: {
			image!:      string
			dbName!:     string
			username!:   string
			password!:   string
			volumeSize!: string
			replicas?:   int & >=1 & <=3 | *1
		}
		messageQueueWorker: {
			image!:                   string
			redisUrl!:                string
			databaseUrl!:             string
			concurrency!:             string
			notificationServiceUrl!:  string
			replicas?:                int & >=1 & <=20 | *5
		}
	}
}
