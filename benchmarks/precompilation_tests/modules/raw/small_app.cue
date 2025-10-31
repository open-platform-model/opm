package raw_small

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Small application with 3 components demonstrating typical composite usage
smallApp: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "small-web-app"
		version:     "1.0.0"
		description: "A small web application with frontend, cache, and config"
	}

	// Three components using composite and primitive elements
	components: {
		// Frontend web service using StatelessWorkload composite
		frontend: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "frontend"
				name: "frontend"
			}

			// Uses StatelessWorkload composite - will need resolution at runtime
			// StatelessWorkload composes: Container, SidecarContainers, InitContainers,
			// Replicas, RestartPolicy, UpdateStrategy, HealthCheck
			statelessWorkload: {
				container: {
					name:  "nginx"
					image: "nginx:1.21"
					ports: {
						http: {
							name:       "http"
							targetPort: 80
							protocol:   "TCP"
						}
					}
				}
				replicas: {
					count: 3
				}
				healthCheck: {
					liveness: {
						httpGet: {
							path:   "/health"
							port:   80
							scheme: "HTTP"
						}
					}
				}
			}
		}

		// Cache service using StatelessWorkload composite
		cache: elements.#StatelessWorkload & {
			#metadata: {
				#id:  "cache"
				name: "cache"
			}

			statelessWorkload: {
				container: {
					name:  "redis"
					image: "redis:6.2"
					ports: {
						redis: {
							name:       "redis"
							targetPort: 6379
							protocol:   "TCP"
						}
					}
				}
				replicas: {
					count: 2
				}
			}
		}

		// Config resource using primitive element (no composite)
		appconfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "appconfig"
				name: "appconfig"
			}

			// Uses primitive element directly - no resolution needed
			configMap: {
				data: {
					"app.env":   "production"
					"api.url":   "https://api.example.com"
					"cache.ttl": "3600"
					"log.level": "info"
				}
			}
		}
	}

	// Configuration schema
	values: {
		frontendReplicas: int | *3
		cacheReplicas:    int | *2
	}
}
