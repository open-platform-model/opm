package compiled_small

import (
	opm "github.com/open-platform-model/core/v0"
	elements "github.com/open-platform-model/core/benchmark/elements"
)

// Small application - PRECOMPILED version with all composites resolved to primitives
// This represents the optimized "Module" after compilation from ModuleDefinition
// Instead of using #StatelessWorkload composite, components directly compose primitives+modifiers
smallAppCompiled: opm.#ModuleDefinition & {
	#apiVersion: "core.opm.dev/v0"
	#kind:       "ModuleDefinition"

	#metadata: {
		name:        "small-web-app"
		version:     "1.0.0"
		description: "A small web application with frontend, cache, and config (PRECOMPILED)"
		annotations: {
			"opm.dev/compiled":    "true"
			"opm.dev/compiled-at": "2025-10-29T00:00:00Z"
			"opm.dev/compiler":    "opm-compiler-v1.0.0"
		}
	}

	components: {
		// Frontend - StatelessWorkload FLATTENED to primitives + modifiers
		// Instead of: elements.#StatelessWorkload
		// We use: #Container & #Replicas & #RestartPolicy & #UpdateStrategy & #HealthCheck
		frontend: opm.#Component & {
			#metadata: {
				#id:  "frontend"
				name: "frontend"
				annotations: {
					"opm.dev/flattened":        "true"
					"opm.dev/origin-composite": "elements.opm.dev/core/v0.StatelessWorkload"
				}
				// Labels are automatically merged from elements
				labels: {
					"core.opm.dev/category":      "workload"
					"core.opm.dev/workload-type": "stateless"
				}
			}

			// Manually compose the elements that StatelessWorkload would have composed
			#elements: {
				(elements.#ContainerElement.#fullyQualifiedName):      elements.#ContainerElement
				(elements.#ReplicasElement.#fullyQualifiedName):       elements.#ReplicasElement
				(elements.#RestartPolicyElement.#fullyQualifiedName):  elements.#RestartPolicyElement
				(elements.#UpdateStrategyElement.#fullyQualifiedName): elements.#UpdateStrategyElement
				(elements.#HealthCheckElement.#fullyQualifiedName):    elements.#HealthCheckElement
			}

			// Provide concrete values for each element
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

		// Cache - StatelessWorkload FLATTENED (fewer modifiers used)
		cache: opm.#Component & {
			#metadata: {
				#id:  "cache"
				name: "cache"
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
			}

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

		// Config - Already primitive, no flattening needed
		appconfig: elements.#ConfigMap & {
			#metadata: {
				#id:  "appconfig"
				name: "appconfig"
				annotations: {
					"opm.dev/flattened": "false"
					"opm.dev/note":      "already primitive, no compilation needed"
				}
			}

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

	// Configuration schema - same as raw version
	values: {
		frontendReplicas: int | *3
		cacheReplicas:    int | *2
	}
}
