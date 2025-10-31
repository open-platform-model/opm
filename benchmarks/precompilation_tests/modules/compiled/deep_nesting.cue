package compiled_deep

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Deep Nesting Test - PRECOMPILED version with all 4-level composites flattened to primitives
// This demonstrates the maximum nesting overhead reduction
deepNestingAppCompiled: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "deep-nesting-test"
		version:     "1.0.0"
		description: "Test module with 4-level nested composites flattened to primitives (PRECOMPILED)"
		annotations: {
			"opm.dev/compiled":       "true"
			"opm.dev/compiled-at":    "2025-10-29T00:00:00Z"
			"opm.dev/compiler":       "opm-compiler-v1.0.0"
			"opm.dev/nesting-level":  "4"
			"opm.dev/test-purpose":   "performance-benchmarking"
		}
	}

	components: {
		// User Microservice - MicroserviceStack 4-LEVEL FLATTENING
		// Split into 4 separate components: database, service, config, secrets

		// 1. User Database (from MicroserviceStack -> SimpleDatabase -> StatefulWorkload -> primitives)
		userMicroserviceDb: opm.#Component & {
			#metadata: {
				#id:  "userMicroserviceDb"
				name: "user-db"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.SimpleDatabase -> elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "4"
					"opm.dev/component-role":         "database"
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
				image: "postgres:15"
				ports: db: {
					name:       "db"
					targetPort: 5432
					protocol:   "TCP"
				}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value:       "users"}
					POSTGRES_USER: {name: "POSTGRES_USER", value:   "userapp"}
					POSTGRES_PASSWORD: {name: "POSTGRES_PASSWORD", value: "userpass"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "user-db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "100Gi"
				}
			}
		}

		// 2. User Service (from MicroserviceStack -> StatelessWorkload -> primitives)
		userMicroserviceService: opm.#Component & {
			#metadata: {
				#id:  "userMicroserviceService"
				name: "user-service"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatelessWorkload"
					"opm.dev/flattening-depth":       "4"
					"opm.dev/component-role":         "service"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):  elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}

			container: {
				name:  "service"
				image: "mycompany/user-service:v2.0.0"
				ports: http: {
					name:       "http"
					targetPort: 8080
					protocol:   "TCP"
				}
			}
			replicas: count: 5
			healthCheck: {
				liveness: httpGet: {
					path:   "/health"
					port:   8080
					scheme: "HTTP"
				}
			}
		}

		// 3. User Config (from MicroserviceStack -> ConfigMap)
		userMicroserviceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "userMicroserviceConfig"
				name: "user-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
					"opm.dev/component-role":   "config"
				}
			}

			configMap: data: {
				"log.level":       "info"
				"cache.enabled":   "true"
				"max.connections": "100"
			}
		}

		// 4. User Secrets (from MicroserviceStack -> Secret)
		userMicroserviceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "userMicroserviceSecrets"
				name: "user-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
					"opm.dev/component-role":   "secrets"
				}
			}

			secret: data: {
				"jwt.secret":  "encrypted-jwt-secret"
				"api.key":     "encrypted-api-key"
				"db.password": "encrypted-db-pass"
			}
		}

		// Order Microservice - MicroserviceStack 4-LEVEL FLATTENING

		// 5. Order Database
		orderMicroserviceDb: opm.#Component & {
			#metadata: {
				#id:  "orderMicroserviceDb"
				name: "order-db"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.SimpleDatabase -> elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "4"
					"opm.dev/component-role":         "database"
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
				image: "postgres:15"
				ports: db: {
					name:       "db"
					targetPort: 5432
					protocol:   "TCP"
				}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value:       "orders"}
					POSTGRES_USER: {name: "POSTGRES_USER", value:   "orderapp"}
					POSTGRES_PASSWORD: {name: "POSTGRES_PASSWORD", value: "orderpass"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "order-db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "200Gi"
				}
			}
		}

		// 6. Order Service
		orderMicroserviceService: opm.#Component & {
			#metadata: {
				#id:  "orderMicroserviceService"
				name: "order-service"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatelessWorkload"
					"opm.dev/flattening-depth":       "4"
					"opm.dev/component-role":         "service"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):  elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}

			container: {
				name:  "service"
				image: "mycompany/order-service:v3.0.0"
				ports: http: {
					name:       "http"
					targetPort: 8081
					protocol:   "TCP"
				}
			}
			replicas: count: 8
			healthCheck: {
				liveness: httpGet: {
					path:   "/health"
					port:   8081
					scheme: "HTTP"
				}
			}
		}

		// 7. Order Config
		orderMicroserviceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "orderMicroserviceConfig"
				name: "order-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
					"opm.dev/component-role":   "config"
				}
			}

			configMap: data: {
				"log.level":      "info"
				"queue.enabled":  "true"
				"retry.attempts": "3"
			}
		}

		// 8. Order Secrets
		orderMicroserviceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "orderMicroserviceSecrets"
				name: "order-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
					"opm.dev/component-role":   "secrets"
				}
			}

			secret: data: {
				"payment.api.key": "encrypted-payment-key"
				"webhook.secret":  "encrypted-webhook-secret"
				"db.password":     "encrypted-db-pass"
			}
		}

		// Product Microservice - MicroserviceStack 4-LEVEL FLATTENING

		// 9. Product Database
		productMicroserviceDb: opm.#Component & {
			#metadata: {
				#id:  "productMicroserviceDb"
				name: "product-db"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.SimpleDatabase -> elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "4"
					"opm.dev/component-role":         "database"
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
				image: "postgres:15"
				ports: db: {
					name:       "db"
					targetPort: 5432
					protocol:   "TCP"
				}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value:       "products"}
					POSTGRES_USER: {name: "POSTGRES_USER", value:   "productapp"}
					POSTGRES_PASSWORD: {name: "POSTGRES_PASSWORD", value: "productpass"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "product-db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "500Gi"
				}
			}
		}

		// 10. Product Service
		productMicroserviceService: opm.#Component & {
			#metadata: {
				#id:  "productMicroserviceService"
				name: "product-service"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatelessWorkload"
					"opm.dev/flattening-depth":       "4"
					"opm.dev/component-role":         "service"
				}
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):  elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}

			container: {
				name:  "service"
				image: "mycompany/product-service:v2.5.0"
				ports: http: {
					name:       "http"
					targetPort: 8082
					protocol:   "TCP"
				}
			}
			replicas: count: 10
			healthCheck: {
				liveness: httpGet: {
					path:   "/health"
					port:   8082
					scheme: "HTTP"
				}
			}
		}

		// 11. Product Config
		productMicroserviceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "productMicroserviceConfig"
				name: "product-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
					"opm.dev/component-role":   "config"
				}
			}

			configMap: data: {
				"log.level":      "info"
				"cache.ttl":      "3600"
				"search.enabled": "true"
			}
		}

		// 12. Product Secrets
		productMicroserviceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "productMicroserviceSecrets"
				name: "product-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
					"opm.dev/component-role":   "secrets"
				}
			}

			secret: data: {
				"search.api.key": "encrypted-search-key"
				"cdn.secret":     "encrypted-cdn-secret"
				"db.password":    "encrypted-db-pass"
			}
		}

		// Simple API - Level 2 composite FLATTENED (for comparison)
		simpleAPI: opm.#Component & {
			#metadata: {
				#id:  "simpleAPI"
				name: "simple-api"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatelessWorkload"
					"opm.dev/flattening-depth": "2"
					"opm.dev/note":             "baseline comparison - only 2-level nesting"
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
			}

			container: {
				name:  "gateway"
				image: "nginx:1.21"
				ports: http: {
					name:       "http"
					targetPort: 80
					protocol:   "TCP"
				}
			}
			replicas: count: 3
		}

		// Simple Cache - Level 3 composite FLATTENED (for comparison)
		simpleCache: opm.#Component & {
			#metadata: {
				#id:  "simpleCache"
				name: "simple-cache"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "3"
					"opm.dev/note":                   "mid-level comparison - 3-level nesting"
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
				image: "postgres:15"
				ports: db: {
					name:       "db"
					targetPort: 5432
					protocol:   "TCP"
				}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value:       "cache"}
					POSTGRES_USER: {name: "POSTGRES_USER", value:   "cacheuser"}
					POSTGRES_PASSWORD: {name: "POSTGRES_PASSWORD", value: "cachepass"}
				}
			}
			replicas: count: 1
			volume: cachedata: {
				name: "cache-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "50Gi"
				}
			}
		}

		// Config - Primitive (no flattening needed)
		config: elements.#ConfigMap & {
			#metadata: {
				#id:  "config"
				name: "app-config"
				annotations: {
					"opm.dev/flattened": "false"
					"opm.dev/note":      "primitive - no nesting"
				}
			}

			configMap: data: {
				"app.name":    "deep-nesting-test"
				"app.env":     "benchmark"
				"nesting.max": "4"
			}
		}
	}

	values: {
		// Configuration values
		userServiceReplicas:    int | *5
		orderServiceReplicas:   int | *8
		productServiceReplicas: int | *10

		// Database sizes
		userDBSize:    string | *"100Gi"
		orderDBSize:   string | *"200Gi"
		productDBSize: string | *"500Gi"

		environment: "benchmark" | "test" | *"benchmark"
	}
}
