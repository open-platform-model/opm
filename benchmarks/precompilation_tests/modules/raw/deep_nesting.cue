package raw_deep

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Deep Nesting Test - Demonstrates 4-level composite nesting impact
// This module uses Level 4 composites to measure maximum nesting overhead
deepNestingApp: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "deep-nesting-test"
		version:     "1.0.0"
		description: "Test module with 4-level nested composites to measure nesting overhead"
		annotations: {
			"opm.dev/nesting-level": "4"
			"opm.dev/test-purpose":  "performance-benchmarking"
		}
	}

	components: {
		// MicroserviceStack - Level 4 composite
		// Nesting: MicroserviceStack -> SimpleDatabase -> StatefulWorkload -> Container/Volume
		//                           -> StatelessWorkload -> Container/Replicas/etc
		//                           -> ConfigMap (primitive)
		//                           -> Secret (primitive)
		userMicroservice: elements.#MicroserviceStack & {
			#metadata: {
				#id:  "userMicroservice"
				name: "user-microservice-stack"
				annotations: {
					"opm.dev/nesting-level": "4"
					"opm.dev/composite-chain": "MicroserviceStack -> SimpleDatabase/StatelessWorkload -> StatefulWorkload/Container -> Volume/Replicas"
				}
			}

			microserviceStack: {
				serviceName:  "user-service"
				serviceImage: "mycompany/user-service:v2.0.0"
				servicePort:  8080

				database: {
					engine:   "postgres"
					version:  "15"
					dbName:   "users"
					username: "userapp"
					password: "userpass"
					size:     "100Gi"
				}

				service: {
					replicas: 5
					healthCheck: {
						path: "/health"
						port: 8080
					}
				}

				config: {
					"log.level":      "info"
					"cache.enabled":  "true"
					"max.connections": "100"
				}

				secrets: {
					"jwt.secret":      "encrypted-jwt-secret"
					"api.key":         "encrypted-api-key"
					"db.password":     "encrypted-db-pass"
				}
			}
		}

		// Another MicroserviceStack for comparison
		orderMicroservice: elements.#MicroserviceStack & {
			#metadata: {
				#id:  "orderMicroservice"
				name: "order-microservice-stack"
				annotations: {
					"opm.dev/nesting-level": "4"
				}
			}

			microserviceStack: {
				serviceName:  "order-service"
				serviceImage: "mycompany/order-service:v3.0.0"
				servicePort:  8081

				database: {
					engine:   "postgres"
					version:  "15"
					dbName:   "orders"
					username: "orderapp"
					password: "orderpass"
					size:     "200Gi"
				}

				service: {
					replicas: 8
					healthCheck: {
						path: "/health"
						port: 8081
					}
				}

				config: {
					"log.level":       "info"
					"queue.enabled":   "true"
					"retry.attempts":  "3"
				}

				secrets: {
					"payment.api.key":  "encrypted-payment-key"
					"webhook.secret":   "encrypted-webhook-secret"
					"db.password":      "encrypted-db-pass"
				}
			}
		}

		// Third MicroserviceStack
		productMicroservice: elements.#MicroserviceStack & {
			#metadata: {
				#id:  "productMicroservice"
				name: "product-microservice-stack"
				annotations: {
					"opm.dev/nesting-level": "4"
				}
			}

			microserviceStack: {
				serviceName:  "product-service"
				serviceImage: "mycompany/product-service:v2.5.0"
				servicePort:  8082

				database: {
					engine:   "postgres"
					version:  "15"
					dbName:   "products"
					username: "productapp"
					password: "productpass"
					size:     "500Gi"
				}

				service: {
					replicas: 10
					healthCheck: {
						path: "/health"
						port: 8082
					}
				}

				config: {
					"log.level":        "info"
					"cache.ttl":        "3600"
					"search.enabled":   "true"
				}

				secrets: {
					"search.api.key":   "encrypted-search-key"
					"cdn.secret":       "encrypted-cdn-secret"
					"db.password":      "encrypted-db-pass"
				}
			}
		}

		// For comparison: a simple Level 2 composite (StatelessWorkload)
		simpleAPI: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "simpleAPI"
				name: "simple-api"
				annotations: {
					"opm.dev/nesting-level": "2"
					"opm.dev/note":          "baseline comparison - only 2-level nesting"
				}
			}

			statelessWorkload: {
				container: {
					name:  "gateway"
					image: "nginx:1.21"
					ports: http: {name: "http", targetPort: 80}
				}
				replicas: count: 3
			}
		}

		// For comparison: a Level 3 composite (SimpleDatabase)
		simpleCache: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "simpleCache"
				name: "simple-cache"
				annotations: {
					"opm.dev/nesting-level": "3"
					"opm.dev/note":          "mid-level comparison - 3-level nesting"
				}
			}

			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "cache"
				username: "cacheuser"
				password: "cachepass"
				persistence: {
					enabled: true
					size:    "50Gi"
				}
			}
		}

		// Level 0: Primitive for baseline
		config: elements.#ConfigMap & {
			#metadata: {
				#id:  "config"
				name: "app-config"
				annotations: {
					"opm.dev/nesting-level": "0"
					"opm.dev/note":          "primitive - no nesting"
				}
			}

			configMap: {
				data: {
					"app.name":    "deep-nesting-test"
					"app.env":     "benchmark"
					"nesting.max": "4"
				}
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
