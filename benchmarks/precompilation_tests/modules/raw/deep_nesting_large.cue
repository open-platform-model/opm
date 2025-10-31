package raw_deep_large

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Deep Nesting Large Test - 28 components with 4-level nesting
// This tests how 4-level composites perform at enterprise scale
// Compare with xlarge_app.cue (28 components, 2-3 level nesting)
deepNestingLargeApp: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "deep-nesting-large-test"
		version:     "1.0.0"
		description: "Enterprise-scale test with 28 components using 4-level nested composites"
		annotations: {
			"opm.dev/test-type":       "performance-benchmark"
			"opm.dev/test-focus":      "deep-nesting-at-scale"
			"opm.dev/component-count": "28"
			"opm.dev/max-nesting":     "4-level"
		}
	}

	components: {
		// ========================================
		// MICROSERVICE STACKS (4-level nesting)
		// Each expands to: database + service + config + secrets
		// ========================================

		// User Management Microservices
		userAuthService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "user-auth"
				serviceImage: "company/user-auth:v2.0.0"
				servicePort:  8080
				database: {
					engine: "postgres"
					dbName: "user_auth"
					size:   "100Gi"
				}
				service: {
					replicas: 5
					healthCheck: {path: "/health", port: 8080}
				}
				config: data: {
					"jwt.expiry":      "3600"
					"session.timeout": "1800"
					"log.level":       "info"
				}
				secrets: data: {
					"jwt.secret":     "enc-jwt-secret"
					"encryption.key": "enc-encryption-key"
					"db.password":    "enc-db-pass"
				}
			}
		}

		userProfileService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "user-profile"
				serviceImage: "company/user-profile:v1.5.0"
				servicePort:  8081
				database: {
					engine: "postgres"
					dbName: "user_profiles"
					size:   "200Gi"
				}
				service: {
					replicas: 8
					healthCheck: {path: "/health", port: 8081}
				}
				config: data: {
					"cache.enabled": "true"
					"cache.ttl":     "300"
					"log.level":     "info"
				}
				secrets: data: {
					"s3.access.key": "enc-s3-access"
					"s3.secret.key": "enc-s3-secret"
					"db.password":   "enc-db-pass"
				}
			}
		}

		// Product Catalog Microservices
		productCatalogService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "product-catalog"
				serviceImage: "company/product-catalog:v3.0.0"
				servicePort:  8082
				database: {
					engine: "postgres"
					dbName: "products"
					size:   "500Gi"
				}
				service: {
					replicas: 12
					healthCheck: {path: "/health", port: 8082}
				}
				config: data: {
					"search.enabled": "true"
					"cache.enabled":  "true"
					"log.level":      "info"
				}
				secrets: data: {
					"search.api.key": "enc-search-key"
					"cdn.secret":     "enc-cdn-secret"
					"db.password":    "enc-db-pass"
				}
			}
		}

		productInventoryService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "product-inventory"
				serviceImage: "company/product-inventory:v2.5.0"
				servicePort:  8083
				database: {
					engine: "postgres"
					dbName: "inventory"
					size:   "300Gi"
				}
				service: {
					replicas: 10
					healthCheck: {path: "/health", port: 8083}
				}
				config: data: {
					"sync.interval":   "60"
					"alert.threshold": "10"
					"log.level":       "info"
				}
				secrets: data: {
					"warehouse.api.key": "enc-warehouse-key"
					"db.password":       "enc-db-pass"
				}
			}
		}

		// Order Management Microservices
		orderService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "order-service"
				serviceImage: "company/order-service:v3.5.0"
				servicePort:  8084
				database: {
					engine: "postgres"
					dbName: "orders"
					size:   "400Gi"
				}
				service: {
					replicas: 15
					healthCheck: {path: "/health", port: 8084}
				}
				config: data: {
					"queue.enabled":  "true"
					"retry.attempts": "3"
					"log.level":      "info"
				}
				secrets: data: {
					"payment.api.key": "enc-payment-key"
					"webhook.secret":  "enc-webhook-secret"
					"db.password":     "enc-db-pass"
				}
			}
		}

		orderFulfillmentService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "order-fulfillment"
				serviceImage: "company/order-fulfillment:v2.0.0"
				servicePort:  8085
				database: {
					engine: "postgres"
					dbName: "fulfillment"
					size:   "250Gi"
				}
				service: {
					replicas: 8
					healthCheck: {path: "/health", port: 8085}
				}
				config: data: {
					"shipping.provider": "fedex"
					"tracking.enabled":  "true"
					"log.level":         "info"
				}
				secrets: data: {
					"shipping.api.key": "enc-shipping-key"
					"db.password":      "enc-db-pass"
				}
			}
		}

		// Payment Processing Microservices
		paymentService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "payment-service"
				serviceImage: "company/payment-service:v4.0.0"
				servicePort:  8086
				database: {
					engine: "postgres"
					dbName: "payments"
					size:   "350Gi"
				}
				service: {
					replicas: 10
					healthCheck: {path: "/health", port: 8086}
				}
				config: data: {
					"pci.compliant":   "true"
					"fraud.detection": "enabled"
					"log.level":       "info"
				}
				secrets: data: {
					"stripe.secret":  "enc-stripe-secret"
					"encryption.key": "enc-encrypt-key"
					"db.password":    "enc-db-pass"
				}
			}
		}

		// Notification Microservices
		notificationService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "notification-service"
				serviceImage: "company/notification-service:v2.2.0"
				servicePort:  8087
				database: {
					engine: "postgres"
					dbName: "notifications"
					size:   "150Gi"
				}
				service: {
					replicas: 6
					healthCheck: {path: "/health", port: 8087}
				}
				config: data: {
					"email.provider": "sendgrid"
					"sms.provider":   "twilio"
					"log.level":      "info"
				}
				secrets: data: {
					"sendgrid.api.key":  "enc-sendgrid-key"
					"twilio.auth.token": "enc-twilio-token"
					"db.password":       "enc-db-pass"
				}
			}
		}

		// Analytics & Reporting Microservices
		analyticsService: elements.#MicroserviceStack & {
			microserviceStack: {
				serviceName:  "analytics-service"
				serviceImage: "company/analytics-service:v1.8.0"
				servicePort:  8088
				database: {
					engine: "postgres"
					dbName: "analytics"
					size:   "600Gi"
				}
				service: {
					replicas: 7
					healthCheck: {path: "/health", port: 8088}
				}
				config: data: {
					"aggregation.interval": "300"
					"retention.days":       "365"
					"log.level":            "info"
				}
				secrets: data: {
					"clickhouse.password": "enc-clickhouse-pass"
					"db.password":         "enc-db-pass"
				}
			}
		}

		// ========================================
		// WEB APPLICATION STACKS (4-level nesting)
		// Each expands to: frontend + backend + database + cache
		// ========================================

		adminPortal: elements.#WebApplicationStack & {
			webApplicationStack: {
				appName: "admin-portal"
				frontend: {
					image:    "company/admin-frontend:v2.0.0"
					replicas: 3
				}
				backend: {
					image:    "company/admin-backend:v2.0.0"
					port:     3000
					replicas: 5
				}
				database: {
					engine: "postgres"
					dbName: "admin"
					size:   "100Gi"
				}
				cache: {
					engine: "redis"
					size:   "10Gi"
				}
			}
		}

		customerPortal: elements.#WebApplicationStack & {
			webApplicationStack: {
				appName: "customer-portal"
				frontend: {
					image:    "company/customer-frontend:v3.0.0"
					replicas: 10
				}
				backend: {
					image:    "company/customer-backend:v3.0.0"
					port:     3001
					replicas: 12
				}
				database: {
					engine: "postgres"
					dbName: "customer"
					size:   "200Gi"
				}
				cache: {
					engine: "redis"
					size:   "20Gi"
				}
			}
		}

		vendorPortal: elements.#WebApplicationStack & {
			webApplicationStack: {
				appName: "vendor-portal"
				frontend: {
					image:    "company/vendor-frontend:v1.5.0"
					replicas: 4
				}
				backend: {
					image:    "company/vendor-backend:v1.5.0"
					port:     3002
					replicas: 6
				}
				database: {
					engine: "postgres"
					dbName: "vendor"
					size:   "150Gi"
				}
				cache: {
					engine: "redis"
					size:   "15Gi"
				}
			}
		}

		// ========================================
		// DATA PLATFORM STACKS (4-level nesting)
		// Each expands to: primary DB + analytics DB + cache + message queue
		// ========================================

		dataPlatform: elements.#DataPlatform & {
			dataPlatform: {
				platformName: "central-data-platform"
				primaryDatabase: {
					engine: "postgres"
					dbName: "primary"
					size:   "1Ti"
				}
				analyticsDatabase: {
					engine: "postgres"
					dbName: "analytics"
					size:   "2Ti"
				}
				cache: {
					engine: "redis"
					size:   "50Gi"
				}
				messageQueue: {
					broker: "kafka"
					size:   "100Gi"
				}
			}
		}

		// ========================================
		// SUPPORTING SERVICES (Mix of nesting levels)
		// ========================================

		// 3-level: SimpleDatabase
		searchDatabase: elements.#SimpleDatabase & {
			simpleDatabase: {
				engine: "postgres"
				dbName: "elasticsearch"
				size:   "500Gi"
			}
		}

		sessionStore: elements.#SimpleDatabase & {
			simpleDatabase: {
				engine: "postgres"
				dbName: "sessions"
				size:   "50Gi"
			}
		}

		// 2-level: StatelessWorkload
		apiGateway: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "gateway"
					image: "nginx:1.21"
					ports: http: {
						name:       "http"
						targetPort: 80
						protocol:   "TCP"
					}
				}
				replicas: {count: 5}
				healthCheck: {
					liveness: httpGet: {
						path:   "/health"
						port:   80
						scheme: "HTTP"
					}
				}
			}
		}

		loadBalancer: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "haproxy"
					image: "haproxy:2.4"
					ports: http: {
						name:       "http"
						targetPort: 80
						protocol:   "TCP"
					}
				}
				replicas: {count: 3}
			}
		}

		reverseProxy: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "traefik"
					image: "traefik:v2.5"
					ports: http: {
						name:       "http"
						targetPort: 80
						protocol:   "TCP"
					}
				}
				replicas: {count: 4}
			}
		}

		// Monitoring & Observability (2-level)
		prometheus: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "prometheus"
					image: "prom/prometheus:v2.30.0"
					ports: http: {
						name:       "http"
						targetPort: 9090
						protocol:   "TCP"
					}
				}
				replicas: {count: 2}
			}
		}

		grafana: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "grafana"
					image: "grafana/grafana:8.2.0"
					ports: http: {
						name:       "http"
						targetPort: 3000
						protocol:   "TCP"
					}
				}
				replicas: {count: 2}
			}
		}

		jaeger: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "jaeger"
					image: "jaegertracing/all-in-one:1.28"
					ports: http: {
						name:       "http"
						targetPort: 16686
						protocol:   "TCP"
					}
				}
				replicas: {count: 1}
			}
		}

		// Background Workers (2-level: TaskWorkload)
		dataBackupWorker: elements.#TaskWorkload & {
			taskWorkload: {
				container: {
					name:  "backup-worker"
					image: "company/backup-worker:v1.0.0"
				}
				restartPolicy: {policy: "OnFailure"}
			}
		}

		reportGeneratorWorker: elements.#TaskWorkload & {
			taskWorkload: {
				container: {
					name:  "report-worker"
					image: "company/report-worker:v1.0.0"
				}
				restartPolicy: {policy: "OnFailure"}
			}
		}

		dataCleanupWorker: elements.#TaskWorkload & {
			taskWorkload: {
				container: {
					name:  "cleanup-worker"
					image: "company/cleanup-worker:v1.0.0"
				}
				restartPolicy: {policy: "OnFailure"}
			}
		}

		metricsCollector: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "metrics-collector"
					image: "company/metrics-collector:v1.0.0"
					ports: http: {
						name:       "http"
						targetPort: 8080
						protocol:   "TCP"
					}
				}
				replicas: {count: 2}
			}
		}

		logAggregator: elements.#StatelessWorkload & {
			statelessWorkload: {
				container: {
					name:  "log-aggregator"
					image: "fluent/fluentd:v1.14"
					ports: http: {
						name:       "http"
						targetPort: 24224
						protocol:   "TCP"
					}
				}
				replicas: {count: 3}
			}
		}

		// Primitives (0-level)
		globalConfig: elements.#ConfigMap & {
			configMap: {
				data: {
					"app.name":        "deep-nesting-large-enterprise"
					"app.env":         "production"
					"region":          "us-east-1"
					"max.nesting":     "4"
					"component.count": "28"
				}
			}
		}

		globalSecrets: elements.#Secret & {
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
		// Configuration values
		environment:     "production" | "staging" | *"production"
		region:          "us-east-1" | "us-west-2" | *"us-east-1"
		maxNestingLevel: 4
		componentCount:  28

		// Service replicas
		userServiceReplicas:    int | *5
		productServiceReplicas: int | *12
		orderServiceReplicas:   int | *15
		paymentServiceReplicas: int | *10

		// Database sizes
		totalDatabaseSize: "6Ti"
	}
}
