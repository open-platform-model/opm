package webapi

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
	network_traits "opm.dev/traits/network@v1"
)

// Simple web+API module for testing
core.#ModuleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/modules/test@v1"
		name:        "webapi-app"
		version:     "1.0.0"
		description: "Test module with web frontend and API backend"
		labels: {
			"env":  "test"
			"team": "platform"
		}
	}

	#components: {
		web: {
			metadata: {
				name: "web-server"
				labels: {
					"tier": "frontend"
				}
			}

			// Container resource
			workload_resources.#Container
			// Replicas trait
			workload_traits.#Replicas
			// Health check trait
			workload_traits.#HealthCheck
			// Expose trait
			network_traits.#Expose

			spec: {
				container: {
					name:  metadata.name
					image: #values.web.image
					ports: {
						http: {
							name:       "http"
							targetPort: 80
							protocol:   "TCP"
						}
					}
				}
				replicas: #values.web.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 80
						}
						initialDelaySeconds: 10
						periodSeconds:       30
					}
				}
				expose: {
					ports: {
						http: {
							port:       80
							targetPort: 80
							protocol:   "TCP"
						}
					}
				}
			}
		}

		api: {
			metadata: {
				name: "api-server"
				labels: {
					"tier": "backend"
				}
			}

			// Container resource
			workload_resources.#Container
			// Replicas trait
			workload_traits.#Replicas
			// Expose trait
			network_traits.#Expose

			spec: {
				container: {
					name:  metadata.name
					image: #values.api.image
					ports: {
						api: {
							name:       "api"
							targetPort: 8080
							protocol:   "TCP"
						}
					}
					env: {
						API_PORT: "8080"
					}
				}
				replicas: #values.api.replicas
				expose: {
					ports: {
						api: {
							port:       8080
							targetPort: 8080
							protocol:   "TCP"
						}
					}
				}
			}
		}
	}

	// Value schema
	#values: {
		web: {
			image!:    string
			replicas?: int & >=1 & <=10 | *2
		}
		api: {
			image!:    string
			replicas?: int & >=1 & <=10 | *3
		}
	}
}
