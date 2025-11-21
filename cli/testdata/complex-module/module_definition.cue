package complex

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Multi-component module for testing multiple workload types
core.#ModuleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/modules/test@v1"
		name:        "complex-app"
		version:     "1.0.0"
		description: "Test module with multiple components and traits"
		labels: {
			"type": "multi-tier"
			"env":  "test"
		}
	}

	#components: {
		frontend: {
			metadata: {
				name: "frontend"
				labels: {
					"tier": "frontend"
				}
			}

			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#SidecarContainers

			spec: {
				container: {
					name:  metadata.name
					image: #values.frontend.image
					ports: {
						http: {
							name:       "http"
							targetPort: 80
							protocol:   "TCP"
						}
					}
				}
				replicas: #values.frontend.replicas
				sidecarContainers: [
					{
						name:  "log-collector"
						image: "fluent/fluent-bit:latest"
					},
				]
			}
		}

		backend: {
			metadata: {
				name: "backend"
				labels: {
					"tier": "backend"
				}
			}

			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#InitContainers

			spec: {
				container: {
					name:  metadata.name
					image: #values.backend.image
					ports: {
						api: {
							name:       "api"
							targetPort: 8080
							protocol:   "TCP"
						}
					}
				}
				replicas: #values.backend.replicas
				initContainers: [
					{
						name:  "db-migration"
						image: "migrate/migrate:latest"
					},
				]
			}
		}

		cache: {
			metadata: {
				name: "cache"
				labels: {
					"tier": "cache"
				}
			}

			workload_resources.#Container

			spec: {
				container: {
					name:  metadata.name
					image: #values.cache.image
					ports: {
						redis: {
							name:       "redis"
							targetPort: 6379
							protocol:   "TCP"
						}
					}
				}
			}
		}

		worker: {
			metadata: {
				name: "worker"
				labels: {
					"tier": "worker"
				}
			}

			workload_resources.#Container
			workload_traits.#JobConfig

			spec: {
				container: {
					name:  metadata.name
					image: #values.worker.image
				}
				jobConfig: {
					backoffLimit: 3
					completions:  1
				}
			}
		}
	}

	// Value schema
	#values: {
		frontend: {
			image!:    string
			replicas?: int & >=1 & <=10 | *2
		}
		backend: {
			image!:    string
			replicas?: int & >=1 & <=10 | *3
		}
		cache: {
			image!: string
		}
		worker: {
			image!: string
		}
	}
}
