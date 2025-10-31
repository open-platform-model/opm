package compiled_large

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Large e-commerce application - PRECOMPILED version with all composites resolved to primitives
// This represents the optimized "Module" after compilation from ModuleDefinition
// Note: SimpleDatabase components show 2-level flattening (SimpleDatabase -> StatefulWorkload -> primitives)
largeAppCompiled: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "large-ecommerce-platform"
		version:     "1.0.0"
		description: "A large e-commerce platform with multiple services, databases, and resources (PRECOMPILED)"
		annotations: {
			"opm.dev/compiled":    "true"
			"opm.dev/compiled-at": "2025-10-29T00:00:00Z"
			"opm.dev/compiler":    "opm-compiler-v1.0.0"
		}
	}

	components: {
		// API Gateway - StatelessWorkload FLATTENED
		apiGateway: opm.#Component & {
			#metadata: {
				#id:  "apiGateway"
				name: "api-gateway"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatelessWorkload"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):           elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):            elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):       elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName):      elements.#UpdateStrategyElement
				(elements.#HealthCheckElement.#fullyQualifiedName):         elements.#HealthCheckElement
				(elements.#SidecarContainersElement.#fullyQualifiedName):   elements.#SidecarContainersElement
			}

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
			replicas: count: 5
			healthCheck: {
				liveness: httpGet: {
					path:   "/status"
					port:   8000
					scheme: "HTTP"
				}
				readiness: httpGet: {
					path:   "/status"
					port:   8000
					scheme: "HTTP"
				}
			}
			sidecarContainers: [{
				name:  "metrics-exporter"
				image: "prom/kong-exporter:latest"
			}]
		}

		// Product Service - StatelessWorkload FLATTENED
		productService: opm.#Component & {
			#metadata: {
				#id:  "productService"
				name: "product-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatelessWorkload"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):     elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):      elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName): elements.#RestartPolicyElement
				(elements.#HealthCheckElement.#fullyQualifiedName):   elements.#HealthCheckElement
			}

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
			replicas: count: 8
		}

		// User Service - StatelessWorkload FLATTENED
		userService: opm.#Component & {
			#metadata: {
				#id:  "userService"
				name: "user-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatelessWorkload"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):    elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):     elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):  elements.#HealthCheckElement
			}

			container: {
				name:  "user-api"
				image: "mycompany/user-service:v1.5.2"
			}
			replicas: count: 6
		}

		// Order Service - StatelessWorkload FLATTENED
		orderService: opm.#Component & {
			#metadata: {
				#id:  "orderService"
				name: "order-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatelessWorkload"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
			}

			container: {
				name:  "order-api"
				image: "mycompany/order-service:v3.0.1"
			}
			replicas: count: 10
		}

		// Product Database - SimpleDatabase 2-LEVEL FLATTENING
		// SimpleDatabase -> StatefulWorkload -> Container + Replicas + RestartPolicy + UpdateStrategy + Volume
		productDb: opm.#Component & {
			#metadata: {
				#id:  "productDb"
				name: "product-database"
				annotations: {
					"opm.dev/flattened":           "true"
					"opm.dev/origin-composite":    "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":    "2"
					"opm.dev/note":                "2-level composite flattening: SimpleDatabase -> StatefulWorkload -> primitives"
				}
				labels: {
					"core.opm.dev/category":      "data"
					"core.opm.dev/workload-type": "stateful"
				}
			}

			// All elements from 2-level flattening
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):  elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
				(elements.#VolumeElement.#fullyQualifiedName):         elements.#VolumeElement
			}

			container: {
				name:  "database"
				image: "postgres:15"
				ports: {
					db: {
						name:       "db"
						targetPort: 5432
						protocol:   "TCP"
					}
				}
				volumeMounts: {
					dbData: {
						name:      "dbData"
						mountPath: "/var/lib/postgresql/data"
					}
				}
			}
			replicas: count: 3
			volume: {
				dbData: {
					name: "db-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "100Gi"
					}
				}
			}
		}

		// User Database - SimpleDatabase 2-LEVEL FLATTENING
		userDb: opm.#Component & {
			#metadata: {
				#id:  "userDb"
				name: "user-database"
				annotations: {
					"opm.dev/flattened":           "true"
					"opm.dev/origin-composite":    "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":    "2"
				}
				labels: {
					"core.opm.dev/category":      "data"
					"core.opm.dev/workload-type": "stateful"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):  elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
				(elements.#VolumeElement.#fullyQualifiedName):         elements.#VolumeElement
			}

			container: {
				name:  "database"
				image: "mysql:8.0"
				ports: {
					db: {
						name:       "db"
						targetPort: 3306
						protocol:   "TCP"
					}
				}
			}
			replicas: count: 2
			volume: {
				mysqldata: {
					name: "mysql-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "50Gi"
					}
				}
			}
		}

		// Redis Cache - StatefulWorkload FLATTENED
		redisCache: opm.#Component & {
			#metadata: {
				#id:  "redisCache"
				name: "redis-cache"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatefulWorkload"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateful"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}

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
			replicas: count: 3
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

		// Background Worker - TaskWorkload FLATTENED
		backgroundWorker: opm.#Component & {
			#metadata: {
				#id:  "backgroundWorker"
				name: "background-worker"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.TaskWorkload"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "task"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):     elements.#ContainerElement
				(elements.#RestartPolicyElement.#fullyQualifiedName): elements.#RestartPolicyElement
			}

			container: {
				name:  "worker"
				image: "mycompany/background-worker:v1.2.0"
			}
		}

		// Application Config - Already primitive, no flattening needed
		appConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "appConfig"
				name: "app-config"
				annotations: {
					"opm.dev/flattened": "false"
					"opm.dev/note":      "already primitive, no compilation needed"
				}
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

		// Database Secrets - Already primitive, no flattening needed
		dbSecrets: elements.#Secret & {
			#metadata: {
				#id:  "dbSecrets"
				name: "database-secrets"
				annotations: {
					"opm.dev/flattened": "false"
					"opm.dev/note":      "already primitive, no compilation needed"
				}
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

	// Configuration schema - same as raw version
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
