package compiled_xlarge

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Extra-large comprehensive e-commerce platform - PRECOMPILED version
// All 28 components with composites resolved to primitives
xlargeAppCompiled: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "xlarge-ecommerce-platform"
		version:     "2.0.0"
		description: "A comprehensive enterprise e-commerce platform with 28+ microservices (PRECOMPILED)"
		annotations: {
			"opm.dev/compiled":    "true"
			"opm.dev/compiled-at": "2025-10-29T00:00:00Z"
			"opm.dev/compiler":    "opm-compiler-v1.0.0"
			"opm.dev/component-count": "28"
		}
	}

	components: {
		//////////////////////////////////////////////////////////////////
		// FRONTEND SERVICES (3) - StatelessWorkload FLATTENED
		//////////////////////////////////////////////////////////////////

		webUI: opm.#Component & {
			#metadata: {
				#id:  "webUI"
				name: "web-ui"
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
				(elements.#ContainerElement.#fullyQualifiedName):          elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):           elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):        elements.#HealthCheckElement
				(elements.#SidecarContainersElement.#fullyQualifiedName): elements.#SidecarContainersElement
			}
			container: {
				name:  "web-ui"
				image: "mycompany/web-ui:v3.0.0"
				ports: {
					http: {name: "http", targetPort: 3000}
					metrics: {name: "metrics", targetPort: 9090}
				}
			}
			replicas: count: 10
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 3000, scheme: "HTTP"}
				readiness: httpGet: {path: "/ready", port: 3000, scheme: "HTTP"}
			}
			sidecarContainers: [{name: "nginx-cache", image: "nginx:1.21"}]
		}

		mobileAPI: opm.#Component & {
			#metadata: {
				#id:  "mobileAPI"
				name: "mobile-api-gateway"
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
				(elements.#ContainerElement.#fullyQualifiedName):   elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):    elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName): elements.#HealthCheckElement
			}
			container: {
				name:  "mobile-gateway"
				image: "mycompany/mobile-api:v2.5.0"
				ports: {
					http: {name: "http", targetPort: 8080}
					grpc: {name: "grpc", targetPort: 9000}
				}
			}
			replicas: count: 8
			healthCheck: liveness: httpGet: {path: "/healthz", port: 8080, scheme: "HTTP"}
		}

		adminPortal: opm.#Component & {
			#metadata: {
				#id:  "adminPortal"
				name: "admin-portal"
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
				(elements.#ContainerElement.#fullyQualifiedName):   elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):    elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName): elements.#HealthCheckElement
			}
			container: {
				name:  "admin"
				image: "mycompany/admin-portal:v1.8.0"
				ports: http: {name: "http", targetPort: 4000}
			}
			replicas: count: 3
			healthCheck: liveness: httpGet: {path: "/", port: 4000, scheme: "HTTP"}
		}

		//////////////////////////////////////////////////////////////////
		// BACKEND SERVICES (8) - StatelessWorkload FLATTENED
		//////////////////////////////////////////////////////////////////

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
				(elements.#ContainerElement.#fullyQualifiedName):   elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):    elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName): elements.#HealthCheckElement
			}
			container: {
				name:  "product-api"
				image: "mycompany/product-service:v3.2.0"
				ports: {
					http: {name: "http", targetPort: 8000}
					grpc: {name: "grpc", targetPort: 9000}
				}
				env: {
					DB_HOST: {name: "DB_HOST", value: "productdb"}
					CACHE_HOST: {name: "CACHE_HOST", value: "redis-cache"}
				}
			}
			replicas: count: 12
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8000, scheme: "HTTP"}
				readiness: httpGet: {path: "/ready", port: 8000, scheme: "HTTP"}
			}
		}

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
				(elements.#ContainerElement.#fullyQualifiedName):   elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):    elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName): elements.#HealthCheckElement
			}
			container: {
				name:  "user-api"
				image: "mycompany/user-service:v2.8.0"
				ports: http: {name: "http", targetPort: 8001}
				env: {
					DB_HOST: {name: "DB_HOST", value: "userdb"}
					SESSION_STORE: {name: "SESSION_STORE", value: "session-store"}
				}
			}
			replicas: count: 10
			healthCheck: liveness: httpGet: {path: "/health", port: 8001, scheme: "HTTP"}
		}

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
				(elements.#ContainerElement.#fullyQualifiedName):          elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):           elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName):        elements.#HealthCheckElement
				(elements.#SidecarContainersElement.#fullyQualifiedName): elements.#SidecarContainersElement
			}
			container: {
				name:  "order-api"
				image: "mycompany/order-service:v4.1.0"
				ports: {
					http: {name: "http", targetPort: 8002}
					grpc: {name: "grpc", targetPort: 9002}
				}
				env: {
					DB_HOST: {name: "DB_HOST", value: "orderdb"}
					KAFKA_HOST: {name: "KAFKA_HOST", value: "kafka"}
				}
			}
			replicas: count: 15
			healthCheck: {
				liveness: httpGet: {path: "/health", port: 8002, scheme: "HTTP"}
				readiness: httpGet: {path: "/ready", port: 8002, scheme: "HTTP"}
			}
			sidecarContainers: [{name: "jaeger-agent", image: "jaegertracing/jaeger-agent:latest"}]
		}

		paymentService: opm.#Component & {
			#metadata: {
				#id:  "paymentService"
				name: "payment-service"
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
				(elements.#ContainerElement.#fullyQualifiedName):   elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):    elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName): elements.#HealthCheckElement
			}
			container: {
				name:  "payment-api"
				image: "mycompany/payment-service:v2.0.0"
				ports: {
					http: {name: "http", targetPort: 8003}
					grpc: {name: "grpc", targetPort: 9003}
				}
			}
			replicas: count: 8
			healthCheck: liveness: httpGet: {path: "/health", port: 8003, scheme: "HTTP"}
		}

		inventoryService: opm.#Component & {
			#metadata: {
				#id:  "inventoryService"
				name: "inventory-service"
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
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name:  "inventory-api"
				image: "mycompany/inventory-service:v3.0.0"
				ports: http: {name: "http", targetPort: 8004}
				env: {
					DB_HOST: {name: "DB_HOST", value: "productdb"}
					RABBITMQ_HOST: {name: "RABBITMQ_HOST", value: "rabbitmq"}
				}
			}
			replicas: count: 6
		}

		shippingService: opm.#Component & {
			#metadata: {
				#id:  "shippingService"
				name: "shipping-service"
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
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name:  "shipping-api"
				image: "mycompany/shipping-service:v1.5.0"
				ports: http: {name: "http", targetPort: 8005}
			}
			replicas: count: 5
		}

		notificationService: opm.#Component & {
			#metadata: {
				#id:  "notificationService"
				name: "notification-service"
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
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name:  "notification-api"
				image: "mycompany/notification-service:v2.3.0"
				ports: http: {name: "http", targetPort: 8006}
				env: RABBITMQ_HOST: {name: "RABBITMQ_HOST", value: "rabbitmq"}
			}
			replicas: count: 4
		}

		searchService: opm.#Component & {
			#metadata: {
				#id:  "searchService"
				name: "search-service"
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
				(elements.#ContainerElement.#fullyQualifiedName):   elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):    elements.#ReplicasElement
				(elements.#HealthCheckElement.#fullyQualifiedName): elements.#HealthCheckElement
			}
			container: {
				name:  "search-api"
				image: "mycompany/search-service:v3.1.0"
				ports: http: {name: "http", targetPort: 8007}
				env: {
					ES_HOST: {name: "ES_HOST", value: "elasticsearch"}
					CACHE_HOST: {name: "CACHE_HOST", value: "redis-cache"}
				}
			}
			replicas: count: 6
			healthCheck: liveness: httpGet: {path: "/health", port: 8007, scheme: "HTTP"}
		}

		//////////////////////////////////////////////////////////////////
		// DATABASES (5) - SimpleDatabase 2-LEVEL FLATTENING
		//////////////////////////////////////////////////////////////////

		productDB: opm.#Component & {
			#metadata: {
				#id:  "productDB"
				name: "product-database"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "2"
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
				ports: db: {name: "db", targetPort: 5432}
				volumeMounts: dbData: {name: "dbData", mountPath: "/var/lib/postgresql/data"}
			}
			replicas: count: 3
			volume: dbData: {
				name: "db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "500Gi"
				}
			}
		}

		userDB: opm.#Component & {
			#metadata: {
				#id:  "userDB"
				name: "user-database"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "2"
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
				ports: db: {name: "db", targetPort: 5432}
			}
			replicas: count: 3
			volume: dbData: {
				name: "db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "200Gi"
				}
			}
		}

		orderDB: opm.#Component & {
			#metadata: {
				#id:  "orderDB"
				name: "order-database"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "2"
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
				ports: db: {name: "db", targetPort: 5432}
			}
			replicas: count: 3
			volume: dbData: {
				name: "db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "1Ti"
				}
			}
		}

		analyticsDB: opm.#Component & {
			#metadata: {
				#id:  "analyticsDB"
				name: "analytics-database"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "2"
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
				ports: db: {name: "db", targetPort: 5432}
			}
			replicas: count: 3
			volume: dbData: {
				name: "db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "2Ti"
				}
			}
		}

		elasticsearchDB: opm.#Component & {
			#metadata: {
				#id:  "elasticsearchDB"
				name: "elasticsearch"
				annotations: {
					"opm.dev/flattened":              "true"
					"opm.dev/origin-composite":       "elements.opm.dev/core/v0.SimpleDatabase"
					"opm.dev/intermediate-composite": "elements.opm.dev/core/v0.StatefulWorkload"
					"opm.dev/flattening-depth":       "2"
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
				ports: db: {name: "db", targetPort: 5432}
			}
			replicas: count: 3
			volume: dbData: {
				name: "db-data"
				persistentClaim: {
					accessMode: "ReadWriteOnce"
					size:       "300Gi"
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// CACHING LAYER (2) - StatefulWorkload FLATTENED
		//////////////////////////////////////////////////////////////////

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
				image: "redis:7.2"
				ports: redis: {name: "redis", targetPort: 6379}
			}
			replicas: count: 5
			volume: {
				"redis-data": {
					name: "redis-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "50Gi"
					}
				}
			}
		}

		cdnCache: opm.#Component & {
			#metadata: {
				#id:  "cdnCache"
				name: "cdn-cache"
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
				name:  "varnish"
				image: "varnish:7.0"
				ports: http: {name: "http", targetPort: 80}
			}
			replicas: count: 3
			volume: {
				"cache-data": {
					name: "cache-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "100Gi"
					}
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// MESSAGE QUEUE / EVENT BUS (3) - StatefulWorkload FLATTENED
		//////////////////////////////////////////////////////////////////

		kafka: opm.#Component & {
			#metadata: {
				#id:  "kafka"
				name: "kafka"
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
				name:  "kafka"
				image: "confluentinc/cp-kafka:7.5.0"
				ports: {
					kafka: {name: "kafka", targetPort: 9092}
					jmx: {name: "jmx", targetPort: 9999}
				}
			}
			replicas: count: 3
			volume: {
				"kafka-data": {
					name: "kafka-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "200Gi"
					}
				}
			}
		}

		rabbitmq: opm.#Component & {
			#metadata: {
				#id:  "rabbitmq"
				name: "rabbitmq"
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
				name:  "rabbitmq"
				image: "rabbitmq:3.12-management"
				ports: {
					amqp: {name: "amqp", targetPort: 5672}
					management: {name: "management", targetPort: 15672}
				}
			}
			replicas: count: 3
			volume: {
				"rabbitmq-data": {
					name: "rabbitmq-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "50Gi"
					}
				}
			}
		}

		sessionStore: opm.#Component & {
			#metadata: {
				#id:  "sessionStore"
				name: "session-store"
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
				name:  "redis-session"
				image: "redis:7.2"
				ports: redis: {name: "redis", targetPort: 6379}
			}
			replicas: count: 3
			volume: {
				"session-data": {
					name: "session-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "20Gi"
					}
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// BACKGROUND WORKERS (3) - TaskWorkload FLATTENED
		//////////////////////////////////////////////////////////////////

		orderWorker: opm.#Component & {
			#metadata: {
				#id:  "orderWorker"
				name: "order-processing-worker"
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
				name:  "order-worker"
				image: "mycompany/order-worker:v2.0.0"
				env: {
					KAFKA_HOST: {name: "KAFKA_HOST", value: "kafka"}
					DB_HOST: {name: "DB_HOST", value: "orderdb"}
				}
			}
		}

		emailWorker: opm.#Component & {
			#metadata: {
				#id:  "emailWorker"
				name: "email-worker"
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
				name:  "email-worker"
				image: "mycompany/email-worker:v1.5.0"
				env: RABBITMQ_HOST: {name: "RABBITMQ_HOST", value: "rabbitmq"}
			}
		}

		analyticsWorker: opm.#Component & {
			#metadata: {
				#id:  "analyticsWorker"
				name: "analytics-worker"
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
				name:  "analytics-worker"
				image: "mycompany/analytics-worker:v3.0.0"
				env: {
					KAFKA_HOST: {name: "KAFKA_HOST", value: "kafka"}
					DB_HOST: {name: "DB_HOST", value: "analyticsdb"}
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// MONITORING / OBSERVABILITY (3)
		//////////////////////////////////////////////////////////////////

		prometheus: opm.#Component & {
			#metadata: {
				#id:  "prometheus"
				name: "prometheus"
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
				name:  "prometheus"
				image: "prom/prometheus:v2.47.0"
				ports: http: {name: "http", targetPort: 9090}
			}
			replicas: count: 2
			volume: {
				"prometheus-data": {
					name: "prometheus-data"
					persistentClaim: {
						accessMode: "ReadWriteOnce"
						size:       "100Gi"
					}
				}
			}
		}

		grafana: opm.#Component & {
			#metadata: {
				#id:  "grafana"
				name: "grafana"
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
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name:  "grafana"
				image: "grafana/grafana:10.1.0"
				ports: http: {name: "http", targetPort: 3000}
				env: PROMETHEUS_URL: {name: "PROMETHEUS_URL", value: "http://prometheus:9090"}
			}
			replicas: count: 2
		}

		jaeger: opm.#Component & {
			#metadata: {
				#id:  "jaeger"
				name: "jaeger"
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
				(elements.#ContainerElement.#fullyQualifiedName): elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):  elements.#ReplicasElement
			}
			container: {
				name:  "jaeger"
				image: "jaegertracing/all-in-one:1.50"
				ports: {
					ui: {name: "ui", targetPort: 16686}
					collector: {name: "collector", targetPort: 14268}
					zipkin: {name: "zipkin", targetPort: 9411}
				}
			}
			replicas: count: 2
		}

		//////////////////////////////////////////////////////////////////
		// CONFIGURATION / SECRETS (2) - Primitives, no flattening
		//////////////////////////////////////////////////////////////////

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
					"app.name":          "xlarge-ecommerce-platform"
					"app.env":           "production"
					"app.region":        "us-east-1"
					"log.level":         "info"
					"metrics.enabled":   "true"
					"tracing.enabled":   "true"
					"cache.ttl":         "3600"
					"session.timeout":   "1800"
					"max.connections":   "1000"
					"db.pool.size":      "50"
					"kafka.partitions":  "16"
					"kafka.replication": "3"
				}
			}
		}

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
					"product.db.password":    "encrypted-prod-pass"
					"user.db.password":       "encrypted-user-pass"
					"order.db.password":      "encrypted-order-pass"
					"analytics.db.password":  "encrypted-analytics-pass"
					"elasticsearch.password": "encrypted-es-pass"
					"redis.password":         "encrypted-redis-pass"
					"kafka.secret":           "encrypted-kafka-secret"
					"rabbitmq.password":      "encrypted-rabbitmq-pass"
				}
			}
		}
	}

	// Configuration schema - same as raw version
	values: {
		webUIReplicas:          int | *10
		mobileAPIReplicas:      int | *8
		adminPortalReplicas:    int | *3
		productServiceReplicas: int | *12
		userServiceReplicas:    int | *10
		orderServiceReplicas:   int | *15
		paymentServiceReplicas: int | *8
		productDBSize:          string | *"500Gi"
		userDBSize:             string | *"200Gi"
		orderDBSize:            string | *"1Ti"
		analyticsDBSize:        string | *"2Ti"
		redisCacheReplicas:     int | *5
		cdnCacheReplicas:       int | *3
		kafkaReplicas:          int | *3
		rabbitmqReplicas:       int | *3
		environment:            "development" | "staging" | "production" | *"production"
		region:                 string | *"us-east-1"
		enableTracing:          bool | *true
		enableMetrics:          bool | *true
		enableMonitoring:       bool | *true
	}
}
