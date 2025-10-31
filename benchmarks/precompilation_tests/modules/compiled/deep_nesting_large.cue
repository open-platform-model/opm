package compiled_deep_large

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Deep Nesting Large Test - PRECOMPILED with all 4-level composites flattened
// 28 raw components expand to 67 flattened when Level-4 composites are resolved
deepNestingLargeAppCompiled: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "deep-nesting-large-test"
		version:     "1.0.0"
		description: "Enterprise-scale precompiled test (28 raw → 67 flattened)"
		annotations: {
			"opm.dev/compiled":        "true"
			"opm.dev/compiled-at":     "2025-10-29T00:00:00Z"
			"opm.dev/compiler":        "opm-compiler-v1.0.0"
			"opm.dev/raw-components":  "28"
			"opm.dev/flat-components": "67"
			"opm.dev/max-nesting":     "4-level"
		}
	}

	components: {

		// userAuthService - MicroserviceStack 4-LEVEL FLATTENING (database)
		userAuthServiceDb: opm.#Component & {
			#metadata: {
				#id:  "userAuthServiceDb"
				name: "user-auth-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "user_auth"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "user-auth-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "100Gi"}
			}
		}

		// userAuthService - MicroserviceStack 4-LEVEL FLATTENING (service)
		userAuthServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "userAuthServiceSvc"
				name: "user-auth"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/user-auth:latest"
				ports: http: {name: "http", targetPort: 8080, protocol: "TCP"}
			}
			replicas: count: 5
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8080, scheme: "HTTP"}
			}
		}

		// userAuthService - Config
		userAuthServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "userAuthServiceConfig"
				name: "user-auth-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// userAuthService - Secrets
		userAuthServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "userAuthServiceSecrets"
				name: "user-auth-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// userProfileService - MicroserviceStack 4-LEVEL FLATTENING (database)
		userProfileServiceDb: opm.#Component & {
			#metadata: {
				#id:  "userProfileServiceDb"
				name: "user-profile-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "user_profiles"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "user-profile-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "200Gi"}
			}
		}

		// userProfileService - MicroserviceStack 4-LEVEL FLATTENING (service)
		userProfileServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "userProfileServiceSvc"
				name: "user-profile"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/user-profile:latest"
				ports: http: {name: "http", targetPort: 8081, protocol: "TCP"}
			}
			replicas: count: 8
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8081, scheme: "HTTP"}
			}
		}

		// userProfileService - Config
		userProfileServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "userProfileServiceConfig"
				name: "user-profile-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// userProfileService - Secrets
		userProfileServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "userProfileServiceSecrets"
				name: "user-profile-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// productCatalogService - MicroserviceStack 4-LEVEL FLATTENING (database)
		productCatalogServiceDb: opm.#Component & {
			#metadata: {
				#id:  "productCatalogServiceDb"
				name: "product-catalog-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "products"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "product-catalog-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "500Gi"}
			}
		}

		// productCatalogService - MicroserviceStack 4-LEVEL FLATTENING (service)
		productCatalogServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "productCatalogServiceSvc"
				name: "product-catalog"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/product-catalog:latest"
				ports: http: {name: "http", targetPort: 8082, protocol: "TCP"}
			}
			replicas: count: 12
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8082, scheme: "HTTP"}
			}
		}

		// productCatalogService - Config
		productCatalogServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "productCatalogServiceConfig"
				name: "product-catalog-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// productCatalogService - Secrets
		productCatalogServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "productCatalogServiceSecrets"
				name: "product-catalog-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// productInventoryService - MicroserviceStack 4-LEVEL FLATTENING (database)
		productInventoryServiceDb: opm.#Component & {
			#metadata: {
				#id:  "productInventoryServiceDb"
				name: "product-inventory-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "inventory"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "product-inventory-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "300Gi"}
			}
		}

		// productInventoryService - MicroserviceStack 4-LEVEL FLATTENING (service)
		productInventoryServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "productInventoryServiceSvc"
				name: "product-inventory"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/product-inventory:latest"
				ports: http: {name: "http", targetPort: 8083, protocol: "TCP"}
			}
			replicas: count: 10
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8083, scheme: "HTTP"}
			}
		}

		// productInventoryService - Config
		productInventoryServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "productInventoryServiceConfig"
				name: "product-inventory-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// productInventoryService - Secrets
		productInventoryServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "productInventoryServiceSecrets"
				name: "product-inventory-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// orderService - MicroserviceStack 4-LEVEL FLATTENING (database)
		orderServiceDb: opm.#Component & {
			#metadata: {
				#id:  "orderServiceDb"
				name: "order-service-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "orders"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "order-service-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "400Gi"}
			}
		}

		// orderService - MicroserviceStack 4-LEVEL FLATTENING (service)
		orderServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "orderServiceSvc"
				name: "order-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/order-service:latest"
				ports: http: {name: "http", targetPort: 8084, protocol: "TCP"}
			}
			replicas: count: 15
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8084, scheme: "HTTP"}
			}
		}

		// orderService - Config
		orderServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "orderServiceConfig"
				name: "order-service-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// orderService - Secrets
		orderServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "orderServiceSecrets"
				name: "order-service-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// orderFulfillmentService - MicroserviceStack 4-LEVEL FLATTENING (database)
		orderFulfillmentServiceDb: opm.#Component & {
			#metadata: {
				#id:  "orderFulfillmentServiceDb"
				name: "order-fulfillment-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "fulfillment"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "order-fulfillment-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "250Gi"}
			}
		}

		// orderFulfillmentService - MicroserviceStack 4-LEVEL FLATTENING (service)
		orderFulfillmentServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "orderFulfillmentServiceSvc"
				name: "order-fulfillment"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/order-fulfillment:latest"
				ports: http: {name: "http", targetPort: 8085, protocol: "TCP"}
			}
			replicas: count: 8
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8085, scheme: "HTTP"}
			}
		}

		// orderFulfillmentService - Config
		orderFulfillmentServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "orderFulfillmentServiceConfig"
				name: "order-fulfillment-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// orderFulfillmentService - Secrets
		orderFulfillmentServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "orderFulfillmentServiceSecrets"
				name: "order-fulfillment-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// paymentService - MicroserviceStack 4-LEVEL FLATTENING (database)
		paymentServiceDb: opm.#Component & {
			#metadata: {
				#id:  "paymentServiceDb"
				name: "payment-service-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "payments"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "payment-service-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "350Gi"}
			}
		}

		// paymentService - MicroserviceStack 4-LEVEL FLATTENING (service)
		paymentServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "paymentServiceSvc"
				name: "payment-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/payment-service:latest"
				ports: http: {name: "http", targetPort: 8086, protocol: "TCP"}
			}
			replicas: count: 10
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8086, scheme: "HTTP"}
			}
		}

		// paymentService - Config
		paymentServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "paymentServiceConfig"
				name: "payment-service-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// paymentService - Secrets
		paymentServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "paymentServiceSecrets"
				name: "payment-service-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// notificationService - MicroserviceStack 4-LEVEL FLATTENING (database)
		notificationServiceDb: opm.#Component & {
			#metadata: {
				#id:  "notificationServiceDb"
				name: "notification-service-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "notifications"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "notification-service-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "150Gi"}
			}
		}

		// notificationService - MicroserviceStack 4-LEVEL FLATTENING (service)
		notificationServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "notificationServiceSvc"
				name: "notification-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/notification-service:latest"
				ports: http: {name: "http", targetPort: 8087, protocol: "TCP"}
			}
			replicas: count: 6
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8087, scheme: "HTTP"}
			}
		}

		// notificationService - Config
		notificationServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "notificationServiceConfig"
				name: "notification-service-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// notificationService - Secrets
		notificationServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "notificationServiceSecrets"
				name: "notification-service-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// analyticsService - MicroserviceStack 4-LEVEL FLATTENING (database)
		analyticsServiceDb: opm.#Component & {
			#metadata: {
				#id:  "analyticsServiceDb"
				name: "analytics-service-db"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
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
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: {
					POSTGRES_DB: {name: "POSTGRES_DB", value: "analytics"}
					POSTGRES_USER: {name: "POSTGRES_USER", value: "dbuser"}
				}
			}
			replicas: count: 1
			volume: dbdata: {
				name: "analytics-service-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "600Gi"}
			}
		}

		// analyticsService - MicroserviceStack 4-LEVEL FLATTENING (service)
		analyticsServiceSvc: opm.#Component & {
			#metadata: {
				#id:  "analyticsServiceSvc"
				name: "analytics-service"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
					"opm.dev/flattening-depth": "4"
				}
			}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}
			container: {
				name:  "service"
				image: "company/analytics-service:latest"
				ports: http: {name: "http", targetPort: 8088, protocol: "TCP"}
			}
			replicas: count: 7
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8088, scheme: "HTTP"}
			}
		}

		// analyticsService - Config
		analyticsServiceConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "analyticsServiceConfig"
				name: "analytics-service-config"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			configMap: data: {"log.level": "info"}
		}

		// analyticsService - Secrets
		analyticsServiceSecrets: elements.#Secret & {
			#metadata: {
				#id:  "analyticsServiceSecrets"
				name: "analytics-service-secrets"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.MicroserviceStack"
				}
			}
			secret: data: {"db.password": "encrypted-pass"}
		}

		// adminPortal - WebApplicationStack 4-LEVEL FLATTENING (frontend)
		adminPortalFrontend: opm.#Component & {
			#metadata: {#id: "adminPortalFrontend", name: "admin-portal-frontend"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "frontend", image: "company/admin-portal-frontend:latest"
				ports: http: {name: "http", targetPort: 80, protocol: "TCP"}
			}
			replicas: count: 3
		}

		// adminPortal - Backend
		adminPortalBackend: opm.#Component & {
			#metadata: {#id: "adminPortalBackend", name: "admin-portal-backend"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "backend", image: "company/admin-portal-backend:latest"
				ports: http: {name: "http", targetPort: 3000, protocol: "TCP"}
			}
			replicas: count: 5
		}

		// adminPortal - Database
		adminPortalDb: opm.#Component & {
			#metadata: {#id: "adminPortalDb", name: "admin-portal-db"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
			}
			volume: data: {
				name: "admin-portal-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "100Gi"}
			}
		}

		// adminPortal - Cache
		adminPortalCache: opm.#Component & {
			#metadata: {#id: "adminPortalCache", name: "admin-portal-cache"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
			}
			container: {
				name: "cache", image: "redis:7"
				ports: redis: {name: "redis", targetPort: 6379, protocol: "TCP"}
			}
		}

		// customerPortal - WebApplicationStack 4-LEVEL FLATTENING (frontend)
		customerPortalFrontend: opm.#Component & {
			#metadata: {#id: "customerPortalFrontend", name: "customer-portal-frontend"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "frontend", image: "company/customer-portal-frontend:latest"
				ports: http: {name: "http", targetPort: 80, protocol: "TCP"}
			}
			replicas: count: 10
		}

		// customerPortal - Backend
		customerPortalBackend: opm.#Component & {
			#metadata: {#id: "customerPortalBackend", name: "customer-portal-backend"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "backend", image: "company/customer-portal-backend:latest"
				ports: http: {name: "http", targetPort: 3000, protocol: "TCP"}
			}
			replicas: count: 12
		}

		// customerPortal - Database
		customerPortalDb: opm.#Component & {
			#metadata: {#id: "customerPortalDb", name: "customer-portal-db"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
			}
			volume: data: {
				name: "customer-portal-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "100Gi"}
			}
		}

		// customerPortal - Cache
		customerPortalCache: opm.#Component & {
			#metadata: {#id: "customerPortalCache", name: "customer-portal-cache"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
			}
			container: {
				name: "cache", image: "redis:7"
				ports: redis: {name: "redis", targetPort: 6379, protocol: "TCP"}
			}
		}

		// vendorPortal - WebApplicationStack 4-LEVEL FLATTENING (frontend)
		vendorPortalFrontend: opm.#Component & {
			#metadata: {#id: "vendorPortalFrontend", name: "vendor-portal-frontend"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "frontend", image: "company/vendor-portal-frontend:latest"
				ports: http: {name: "http", targetPort: 80, protocol: "TCP"}
			}
			replicas: count: 4
		}

		// vendorPortal - Backend
		vendorPortalBackend: opm.#Component & {
			#metadata: {#id: "vendorPortalBackend", name: "vendor-portal-backend"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "backend", image: "company/vendor-portal-backend:latest"
				ports: http: {name: "http", targetPort: 3000, protocol: "TCP"}
			}
			replicas: count: 6
		}

		// vendorPortal - Database
		vendorPortalDb: opm.#Component & {
			#metadata: {#id: "vendorPortalDb", name: "vendor-portal-db"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
			}
			volume: data: {
				name: "vendor-portal-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "100Gi"}
			}
		}

		// vendorPortal - Cache
		vendorPortalCache: opm.#Component & {
			#metadata: {#id: "vendorPortalCache", name: "vendor-portal-cache"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
			}
			container: {
				name: "cache", image: "redis:7"
				ports: redis: {name: "redis", targetPort: 6379, protocol: "TCP"}
			}
		}

		// dataPlatform - DataPlatform 4-LEVEL FLATTENING (primary database)
		dataPlatformPrimary: opm.#Component & {
			#metadata: {#id: "dataPlatformPrimary", name: "data-platform-primary"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
			}
			volume: data: {
				name: "primary-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "1Ti"}
			}
		}

		// dataPlatform - Analytics Database
		dataPlatformAnalytics: opm.#Component & {
			#metadata: {#id: "dataPlatformAnalytics", name: "data-platform-analytics"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
			}
			volume: data: {
				name: "analytics-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "2Ti"}
			}
		}

		// dataPlatform - Cache
		dataPlatformCache: opm.#Component & {
			#metadata: {#id: "dataPlatformCache", name: "data-platform-cache"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
			}
			container: {
				name: "cache", image: "redis:7"
				ports: redis: {name: "redis", targetPort: 6379, protocol: "TCP"}
			}
		}

		// dataPlatform - Message Queue
		dataPlatformQueue: opm.#Component & {
			#metadata: {#id: "dataPlatformQueue", name: "data-platform-queue"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
			}
			container: {
				name: "kafka", image: "confluentinc/cp-kafka:7.0.0"
				ports: kafka: {name: "kafka", targetPort: 9092, protocol: "TCP"}
			}
		}

		// searchDatabase - SimpleDatabase 3-LEVEL FLATTENING
		searchDatabase: opm.#Component & {
			#metadata: {#id: "searchDatabase", name: "elasticsearch-db"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: POSTGRES_DB: {name: "POSTGRES_DB", value: "elasticsearch"}
			}
			volume: data: {
				name: "elasticsearch-db-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "500Gi"}
			}
		}

		// sessionStore - SimpleDatabase 3-LEVEL FLATTENING
		sessionStore: opm.#Component & {
			#metadata: {#id: "sessionStore", name: "sessions-db"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#VolumeElement.#fullyQualifiedName):    elements.#VolumeElement
			}
			container: {
				name: "database", image: "postgres:15"
				ports: db: {name: "db", targetPort: 5432, protocol: "TCP"}
				env: POSTGRES_DB: {name: "POSTGRES_DB", value: "sessions"}
			}
			volume: data: {
				name: "sessions-db-data"
				persistentClaim: {accessMode: "ReadWriteOnce", size: "50Gi"}
			}
		}

		// apiGateway - StatelessWorkload 2-LEVEL FLATTENING
		apiGateway: opm.#Component & {
			#metadata: {#id: "apiGateway", name: "gateway"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "gateway", image: "nginx:1.21"
				ports: http: {name: "http", targetPort: 80, protocol: "TCP"}
			}
			replicas: count: 5
		}

		// loadBalancer - StatelessWorkload 2-LEVEL FLATTENING
		loadBalancer: opm.#Component & {
			#metadata: {#id: "loadBalancer", name: "haproxy"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "haproxy", image: "haproxy:2.4"
				ports: http: {name: "http", targetPort: 80, protocol: "TCP"}
			}
			replicas: count: 3
		}

		// reverseProxy - StatelessWorkload 2-LEVEL FLATTENING
		reverseProxy: opm.#Component & {
			#metadata: {#id: "reverseProxy", name: "traefik"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "traefik", image: "traefik:v2.5"
				ports: http: {name: "http", targetPort: 80, protocol: "TCP"}
			}
			replicas: count: 4
		}

		// prometheus - StatelessWorkload 2-LEVEL FLATTENING
		prometheus: opm.#Component & {
			#metadata: {#id: "prometheus", name: "prometheus"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "prometheus", image: "prom/prometheus:v2.30.0"
				ports: http: {name: "http", targetPort: 9090, protocol: "TCP"}
			}
			replicas: count: 2
		}

		// grafana - StatelessWorkload 2-LEVEL FLATTENING
		grafana: opm.#Component & {
			#metadata: {#id: "grafana", name: "grafana"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "grafana", image: "grafana/grafana:8.2.0"
				ports: http: {name: "http", targetPort: 3000, protocol: "TCP"}
			}
			replicas: count: 2
		}

		// jaeger - StatelessWorkload 2-LEVEL FLATTENING
		jaeger: opm.#Component & {
			#metadata: {#id: "jaeger", name: "jaeger"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "jaeger", image: "jaegertracing/all-in-one:1.28"
				ports: http: {name: "http", targetPort: 16686, protocol: "TCP"}
			}
			replicas: count: 1
		}

		// metricsCollector - StatelessWorkload 2-LEVEL FLATTENING
		metricsCollector: opm.#Component & {
			#metadata: {#id: "metricsCollector", name: "metrics-collector"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "metrics-collector", image: "company/metrics-collector:v1.0.0"
				ports: http: {name: "http", targetPort: 8080, protocol: "TCP"}
			}
			replicas: count: 2
		}

		// logAggregator - StatelessWorkload 2-LEVEL FLATTENING
		logAggregator: opm.#Component & {
			#metadata: {#id: "logAggregator", name: "log-aggregator"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name: "log-aggregator", image: "fluent/fluentd:v1.14"
				ports: http: {name: "http", targetPort: 24224, protocol: "TCP"}
			}
			replicas: count: 3
		}

		// dataBackupWorker - TaskWorkload 2-LEVEL FLATTENING
		dataBackupWorker: opm.#Component & {
			#metadata: {#id: "dataBackupWorker", name: "backup-worker"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):     elements.#ContainerElement
				(elements.#RestartPolicyElement.#fullyQualifiedName): elements.#RestartPolicyElement
			}
			container: {name: "backup-worker", image: "company/backup-worker:v1.0.0"}
			restartPolicy: {policy: "OnFailure"}
		}

		// reportGeneratorWorker - TaskWorkload 2-LEVEL FLATTENING
		reportGeneratorWorker: opm.#Component & {
			#metadata: {#id: "reportGeneratorWorker", name: "report-worker"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):     elements.#ContainerElement
				(elements.#RestartPolicyElement.#fullyQualifiedName): elements.#RestartPolicyElement
			}
			container: {name: "report-worker", image: "company/report-worker:v1.0.0"}
			restartPolicy: {policy: "OnFailure"}
		}

		// dataCleanupWorker - TaskWorkload 2-LEVEL FLATTENING
		dataCleanupWorker: opm.#Component & {
			#metadata: {#id: "dataCleanupWorker", name: "cleanup-worker"}
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):     elements.#ContainerElement
				(elements.#RestartPolicyElement.#fullyQualifiedName): elements.#RestartPolicyElement
			}
			container: {name: "cleanup-worker", image: "company/cleanup-worker:v1.0.0"}
			restartPolicy: {policy: "OnFailure"}
		}

		// Primitives (no flattening needed)
		globalConfig: elements.#ConfigMap & {
			#metadata: {#id: "globalConfig", name: "app-config"}
			configMap: {
				data: {
					"app.name":        "deep-nesting-large-enterprise"
					"app.env":         "production"
					"component.count": "28"
					"max.nesting":     "4"
				}
			}
		}

		globalSecrets: elements.#Secret & {
			#metadata: {#id: "globalSecrets", name: "app-secrets"}
			secret: {
				data: {
					"master.key": "encrypted-master-key"
					"tls.cert":   "encrypted-tls-cert"
					"tls.key":    "encrypted-tls-key"
				}
			}
		}
	}

	values: {
		environment:     "production" | "staging" | *"production"
		componentCount:  28
		flatComponents:  67
		maxNestingLevel: 4
	}
}
