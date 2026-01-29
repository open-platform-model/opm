package large

import (
	workload_blueprints "opmodel.dev/blueprints/workload@v1"
)

// Large 12-component e-commerce platform using blueprints
// This represents a ModuleDefinition where components reference blueprints
largeModuleDefinition: {
	apiVersion: "opmodel.dev/v1/core"
	kind:       "ModuleDefinition"

	metadata: {
		apiVersion:       "opmodel.dev/benchmarks/large@v0"
		name:             "ECommercePlatform"
		version:          "1.0.0"
		description:      "Complete e-commerce platform with microservices architecture"
		defaultNamespace: ""
	}

	#components: {
		// 1. Frontend - React SPA
		frontend: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "web-frontend"
				labels: {
					"app.opmodel.dev/tier":      "frontend"
					"app.opmodel.dev/component": "ui"
				}
			}

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
		apiGateway: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "api-gateway"
				labels: {
					"app.opmodel.dev/tier":      "gateway"
					"app.opmodel.dev/component": "api-gateway"
				}
			}

			spec: statelessWorkload: {
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
		authService: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "auth-service"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "auth"
				}
			}

			spec: statelessWorkload: {
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
		userService: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "user-service"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "user"
				}
			}

			spec: statelessWorkload: {
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
		productService: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "product-service"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "product"
				}
			}

			spec: statelessWorkload: {
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
		orderService: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "order-service"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "order"
				}
			}

			spec: statelessWorkload: {
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
		paymentService: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "payment-service"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "payment"
				}
			}

			spec: statelessWorkload: {
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
		notificationService: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "notification-service"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "notification"
				}
			}

			spec: statelessWorkload: {
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
		postgresDatabase: {
			workload_blueprints.#StatefulWorkload
			metadata: {
				name: "postgres-database"
				labels: {
					"app.opmodel.dev/tier":      "data"
					"app.opmodel.dev/component": "database"
				}
			}

			spec: statefulWorkload: {
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
		redisCache: {
			workload_blueprints.#StatefulWorkload
			metadata: {
				name: "redis-cache"
				labels: {
					"app.opmodel.dev/tier":      "data"
					"app.opmodel.dev/component": "cache"
				}
			}

			spec: statefulWorkload: {
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
		mongoDatabase: {
			workload_blueprints.#StatefulWorkload
			metadata: {
				name: "mongodb-database"
				labels: {
					"app.opmodel.dev/tier":      "data"
					"app.opmodel.dev/component": "nosql-database"
				}
			}

			spec: statefulWorkload: {
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
		messageQueueWorker: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "mq-worker"
				labels: {
					"app.opmodel.dev/tier":      "backend"
					"app.opmodel.dev/component": "worker"
				}
			}

			spec: statelessWorkload: {
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
