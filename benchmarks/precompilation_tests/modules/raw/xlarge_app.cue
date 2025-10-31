package raw_xlarge

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Extra-large comprehensive e-commerce platform with 28 components
// This demonstrates maximum complexity with deep nesting and varied element usage
xlargeApp: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "xlarge-ecommerce-platform"
		version:     "2.0.0"
		description: "A comprehensive enterprise e-commerce platform with 28+ microservices"
	}

	components: {
		//////////////////////////////////////////////////////////////////
		// FRONTEND SERVICES (3)
		//////////////////////////////////////////////////////////////////

		webUI: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "webUI"
				name: "web-ui"
			}
			statelessWorkload: {
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
		}

		mobileAPI: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "mobileAPI"
				name: "mobile-api-gateway"
			}
			statelessWorkload: {
				container: {
					name:  "mobile-gateway"
					image: "mycompany/mobile-api:v2.5.0"
					ports: {
						http: {name: "http", targetPort: 8080}
						grpc: {name: "grpc", targetPort: 9000}
					}
				}
				replicas: count: 8
				healthCheck: {
					liveness: httpGet: {path: "/healthz", port: 8080, scheme: "HTTP"}
				}
			}
		}

		adminPortal: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "adminPortal"
				name: "admin-portal"
			}
			statelessWorkload: {
				container: {
					name:  "admin"
					image: "mycompany/admin-portal:v1.8.0"
					ports: http: {name: "http", targetPort: 4000}
				}
				replicas: count: 3
				healthCheck: {
					liveness: httpGet: {path: "/", port: 4000, scheme: "HTTP"}
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// BACKEND SERVICES (8)
		//////////////////////////////////////////////////////////////////

		productService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "productService"
				name: "product-service"
			}
			statelessWorkload: {
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
		}

		userService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "userService"
				name: "user-service"
			}
			statelessWorkload: {
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
				healthCheck: {
					liveness: httpGet: {path: "/health", port: 8001, scheme: "HTTP"}
				}
			}
		}

		orderService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "orderService"
				name: "order-service"
			}
			statelessWorkload: {
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
		}

		paymentService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "paymentService"
				name: "payment-service"
			}
			statelessWorkload: {
				container: {
					name:  "payment-api"
					image: "mycompany/payment-service:v2.0.0"
					ports: {
						http: {name: "http", targetPort: 8003}
						grpc: {name: "grpc", targetPort: 9003}
					}
				}
				replicas: count: 8
				healthCheck: {
					liveness: httpGet: {path: "/health", port: 8003, scheme: "HTTP"}
				}
			}
		}

		inventoryService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "inventoryService"
				name: "inventory-service"
			}
			statelessWorkload: {
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
		}

		shippingService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "shippingService"
				name: "shipping-service"
			}
			statelessWorkload: {
				container: {
					name:  "shipping-api"
					image: "mycompany/shipping-service:v1.5.0"
					ports: http: {name: "http", targetPort: 8005}
				}
				replicas: count: 5
			}
		}

		notificationService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "notificationService"
				name: "notification-service"
			}
			statelessWorkload: {
				container: {
					name:  "notification-api"
					image: "mycompany/notification-service:v2.3.0"
					ports: http: {name: "http", targetPort: 8006}
					env: RABBITMQ_HOST: {name: "RABBITMQ_HOST", value: "rabbitmq"}
				}
				replicas: count: 4
			}
		}

		searchService: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "searchService"
				name: "search-service"
			}
			statelessWorkload: {
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
				healthCheck: {
					liveness: httpGet: {path: "/health", port: 8007, scheme: "HTTP"}
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// DATABASES (5) - All use SimpleDatabase (2-level nesting)
		//////////////////////////////////////////////////////////////////

		productDB: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "productDB"
				name: "product-database"
			}
			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "products"
				username: "produser"
				password: "prodpass"
				persistence: {
					enabled: true
					size:    "500Gi"
				}
			}
		}

		userDB: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "userDB"
				name: "user-database"
			}
			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "users"
				username: "useruser"
				password: "userpass"
				persistence: {
					enabled: true
					size:    "200Gi"
				}
			}
		}

		orderDB: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "orderDB"
				name: "order-database"
			}
			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "orders"
				username: "orderuser"
				password: "orderpass"
				persistence: {
					enabled: true
					size:    "1Ti"
				}
			}
		}

		analyticsDB: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "analyticsDB"
				name: "analytics-database"
			}
			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "analytics"
				username: "analyticsuser"
				password: "analyticspass"
				persistence: {
					enabled: true
					size:    "2Ti"
				}
			}
		}

		elasticsearchDB: elements.#SimpleDatabase & {
			#metadata: {
				#id:  "elasticsearchDB"
				name: "elasticsearch"
			}
			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "search"
				username: "searchuser"
				password: "searchpass"
				persistence: {
					enabled: true
					size:    "300Gi"
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// CACHING LAYER (2)
		//////////////////////////////////////////////////////////////////

		redisCache: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "redisCache"
				name: "redis-cache"
			}
			statefulWorkload: {
				container: {
					name:  "redis"
					image: "redis:7.2"
					ports: redis: {name: "redis", targetPort: 6379}
				}
				replicas: count: 5
			}
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

		cdnCache: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "cdnCache"
				name: "cdn-cache"
			}
			statefulWorkload: {
				container: {
					name:  "varnish"
					image: "varnish:7.0"
					ports: http: {name: "http", targetPort: 80}
				}
				replicas: count: 3
			}
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
		// MESSAGE QUEUE / EVENT BUS (2)
		//////////////////////////////////////////////////////////////////

		kafka: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "kafka"
				name: "kafka"
			}
			statefulWorkload: {
				container: {
					name:  "kafka"
					image: "confluentinc/cp-kafka:7.5.0"
					ports: {
						kafka: {name: "kafka", targetPort: 9092}
						jmx: {name: "jmx", targetPort: 9999}
					}
				}
				replicas: count: 3
			}
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

		rabbitmq: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "rabbitmq"
				name: "rabbitmq"
			}
			statefulWorkload: {
				container: {
					name:  "rabbitmq"
					image: "rabbitmq:3.12-management"
					ports: {
						amqp: {name: "amqp", targetPort: 5672}
						management: {name: "management", targetPort: 15672}
					}
				}
				replicas: count: 3
			}
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

		sessionStore: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "sessionStore"
				name: "session-store"
			}
			statefulWorkload: {
				container: {
					name:  "redis-session"
					image: "redis:7.2"
					ports: redis: {name: "redis", targetPort: 6379}
				}
				replicas: count: 3
			}
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
		// BACKGROUND WORKERS (3)
		//////////////////////////////////////////////////////////////////

		orderWorker: elements.#TaskWorkload & {
			#metadata: {
				#id:  "orderWorker"
				name: "order-processing-worker"
			}
			taskWorkload: {
				container: {
					name:  "order-worker"
					image: "mycompany/order-worker:v2.0.0"
					env: {
						KAFKA_HOST: {name: "KAFKA_HOST", value: "kafka"}
						DB_HOST: {name: "DB_HOST", value: "orderdb"}
					}
				}
			}
		}

		emailWorker: elements.#TaskWorkload & {
			#metadata: {
				#id:  "emailWorker"
				name: "email-worker"
			}
			taskWorkload: {
				container: {
					name:  "email-worker"
					image: "mycompany/email-worker:v1.5.0"
					env: RABBITMQ_HOST: {name: "RABBITMQ_HOST", value: "rabbitmq"}
				}
			}
		}

		analyticsWorker: elements.#TaskWorkload & {
			#metadata: {
				#id:  "analyticsWorker"
				name: "analytics-worker"
			}
			taskWorkload: {
				container: {
					name:  "analytics-worker"
					image: "mycompany/analytics-worker:v3.0.0"
					env: {
						KAFKA_HOST: {name: "KAFKA_HOST", value: "kafka"}
						DB_HOST: {name: "DB_HOST", value: "analyticsdb"}
					}
				}
			}
		}

		//////////////////////////////////////////////////////////////////
		// MONITORING / OBSERVABILITY (3)
		//////////////////////////////////////////////////////////////////

		prometheus: elements.#StatefulWorkload & {
			#metadata: {
				#id:  "prometheus"
				name: "prometheus"
			}
			statefulWorkload: {
				container: {
					name:  "prometheus"
					image: "prom/prometheus:v2.47.0"
					ports: {
						http: {name: "http", targetPort: 9090}
					}
				}
				replicas: count: 2
			}
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

		grafana: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "grafana"
				name: "grafana"
			}
			statelessWorkload: {
				container: {
					name:  "grafana"
					image: "grafana/grafana:10.1.0"
					ports: http: {name: "http", targetPort: 3000}
					env: PROMETHEUS_URL: {name: "PROMETHEUS_URL", value: "http://prometheus:9090"}
				}
				replicas: count: 2
			}
		}

		jaeger: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "jaeger"
				name: "jaeger"
			}
			statelessWorkload: {
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
		}

		//////////////////////////////////////////////////////////////////
		// CONFIGURATION / SECRETS (2)
		//////////////////////////////////////////////////////////////////

		appConfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "appConfig"
				name: "app-config"
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

	// Configuration schema
	values: {
		// Replica counts
		webUIReplicas:          int | *10
		mobileAPIReplicas:      int | *8
		adminPortalReplicas:    int | *3
		productServiceReplicas: int | *12
		userServiceReplicas:    int | *10
		orderServiceReplicas:   int | *15
		paymentServiceReplicas: int | *8

		// Database sizes
		productDBSize:   string | *"500Gi"
		userDBSize:      string | *"200Gi"
		orderDBSize:     string | *"1Ti"
		analyticsDBSize: string | *"2Ti"

		// Cache configuration
		redisCacheReplicas: int | *5
		cdnCacheReplicas:   int | *3

		// Message queue replicas
		kafkaReplicas:    int | *3
		rabbitmqReplicas: int | *3

		// Environment
		environment: "development" | "staging" | "production" | *"production"
		region:      string | *"us-east-1"

		// Feature flags
		enableTracing:    bool | *true
		enableMetrics:    bool | *true
		enableMonitoring: bool | *true
	}
}
