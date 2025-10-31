package raw_large

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Large application with 10 components demonstrating complex composite nesting
largeApp: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "large-ecommerce-platform"
		version:     "1.0.0"
		description: "A large e-commerce platform with multiple services, databases, and resources"
	}

	components: {
		// API Gateway - StatelessWorkload composite
		apiGateway: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "apiGateway"
				name: "api-gateway"
			}

			statelessWorkload: {
				container: {
					name:  "gateway"
					image: "kong:3.0"
					ports: {
						http: {
							name:       "http"
							targetPort: 8000
							protocol:   "TCP"
						}
						admin: {
							name:       "admin"
							targetPort: 8001
							protocol:   "TCP"
						}
					}
				}
				replicas: {
					count: 5
				}
				healthCheck: {
					liveness: {
						httpGet: {
							path:   "/status"
							port:   8000
							scheme: "HTTP"
						}
					}
					readiness: {
						httpGet: {
							path:   "/status"
							port:   8000
							scheme: "HTTP"
						}
					}
				}
				sidecarContainers: [{
					name:  "metrics-exporter"
					image: "prom/kong-exporter:latest"
				}]
			}
		}

		// Product Service - StatelessWorkload
		productService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "productService"
				name: "product-service"
			}

			statelessWorkload: {
				container: {
					name:  "product-api"
					image: "mycompany/product-service:v2.1.0"
					env: {
						DB_HOST: {
							name:  "DB_HOST"
							value: "productdb"
						}
						CACHE_HOST: {
							name:  "CACHE_HOST"
							value: "redis-cache"
						}
					}
				}
				replicas: {
					count: 8
				}
			}
		}

		// User Service - StatelessWorkload
		userService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "userService"
				name: "user-service"
			}

			statelessWorkload: {
				container: {
					name:  "user-api"
					image: "mycompany/user-service:v1.5.2"
				}
				replicas: {
					count: 6
				}
			}
		}

		// Order Service - StatelessWorkload
		orderService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "orderService"
				name: "order-service"
			}

			statelessWorkload: {
				container: {
					name:  "order-api"
					image: "mycompany/order-service:v3.0.1"
				}
				replicas: {
					count: 10
				}
			}
		}

		// Product Database - SimpleDatabase (2-level nesting: SimpleDatabase -> StatefulWorkload -> Container)
		productDb: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "productDb"
				name: "product-database"
			}

			// SimpleDatabase composes StatefulWorkload (which is itself a composite!)
			// This creates 2-level nesting for benchmarking
			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "products"
				username: "produser"
				password: "prodpass"
				persistence: {
					enabled: true
					size:    "100Gi"
				}
			}
		}

		// User Database - SimpleDatabase (2-level nesting)
		userDb: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "userDb"
				name: "user-database"
			}

			simpleDatabase: {
				engine:   "mysql"
				version:  "8.0"
				dbName:   "users"
				username: "useruser"
				password: "userpass"
				persistence: {
					enabled: true
					size:    "50Gi"
				}
			}
		}

		// Redis Cache - StatefulWorkload
		redisCache: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "redisCache"
				name: "redis-cache"
			}

			statefulWorkload: {
				container: {
					name:  "redis"
					image: "redis:7.0"
					ports: {
						redis: {
							name:       "redis"
							targetPort: 6379
							protocol:   "TCP"
						}
					}
				}
				replicas: {
					count: 3
				}
			}

			volume: {
				"redis-data": {
					name: "redis-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "10Gi"
					}
				}
			}
		}

		// Background Worker - TaskWorkload
		backgroundWorker: elements.#TaskWorkload & {
			#metadata: {
				#id:  "backgroundWorker"
				name: "background-worker"
			}

			taskWorkload: {
				container: {
					name:  "worker"
					image: "mycompany/background-worker:v1.2.0"
				}
			}
		}

		// Application Config - ConfigMap primitive
		appConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "appConfig"
				name: "app-config"
			}

			configMap: {
				data: {
					"app.name":        "ecommerce-platform"
					"app.env":         "production"
					"api.gateway.url": "https://api.example.com"
					"cache.ttl":       "3600"
					"log.level":       "info"
					"db.pool.size":    "20"
				}
			}
		}

		// Database Secrets - Secret primitive
		dbSecrets: elements.#Secret & {
			#metadata: {
				#id:  "dbSecrets"
				name: "database-secrets"
			}

			secret: {
				data: {
					"postgres.password": "encrypted-password-1"
					"mysql.password":    "encrypted-password-2"
					"redis.password":    "encrypted-password-3"
				}
			}
		}
	}

	// Configuration schema
	values: {
		gatewayReplicas:        int | *5
		productServiceReplicas: int | *8
		userServiceReplicas:    int | *6
		orderServiceReplicas:   int | *10
		productDbSize:          string | *"100Gi"
		userDbSize:             string | *"50Gi"
		environment:            "development" | "staging" | "production" | *"production"
	}
}
