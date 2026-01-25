package simple

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Simple 2-component web application with blueprints expanded
// This represents a Module where blueprints have been flattened into resources + traits
simpleModule: core.#Module & {
	metadata: {
		apiVersion:  "opm.dev/benchmarks/simple@v0"
		name:        "SimpleWebApp"
		version:     "1.0.0"
		description: "Simple web application with frontend and API backend (compiled/flattened)"
	}

	#components: {
		frontend: core.#ComponentDefinition & {
			metadata: {
				name: "web-frontend"
				labels: {
					"app.opm.dev/tier": "frontend"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait
			workload_resources.#Container
			workload_traits.#Replicas

			spec: {
				container: {
					name:  "frontend"
					image: #values.frontend.image
					ports: {
						http: {
							name:       "http"
							targetPort: 3000
							protocol:   "TCP"
						}
					}
					env: {
						API_URL: {
							name:  "API_URL"
							value: #values.frontend.apiUrl
						}
					}
					resources: {
						requests: {
							cpu:    "100m"
							memory: "128Mi"
						}
						limits: {
							cpu:    "500m"
							memory: "512Mi"
						}
					}
				}
				replicas: #values.frontend.replicas
			}
		}

		api: core.#ComponentDefinition & {
			metadata: {
				name: "api-backend"
				labels: {
					"app.opm.dev/tier": "backend"
				}
			}

			// Blueprint expanded: StatelessWorkload → ContainerResource + ReplicasTrait + HealthCheckTrait
			workload_resources.#Container
			workload_traits.#Replicas
			workload_traits.#HealthCheck

			spec: {
				container: {
					name:  "api"
					image: #values.api.image
					ports: {
						http: {
							name:       "http"
							targetPort: 8080
							protocol:   "TCP"
						}
					}
					env: {
						PORT: {
							name:  "PORT"
							value: "8080"
						}
						NODE_ENV: {
							name:  "NODE_ENV"
							value: #values.api.environment
						}
					}
					resources: {
						requests: {
							cpu:    "200m"
							memory: "256Mi"
						}
						limits: {
							cpu:    "1000m"
							memory: "1Gi"
						}
					}
				}
				replicas: #values.api.replicas
				healthCheck: {
					livenessProbe: {
						httpGet: {
							path: "/health"
							port: 8080
						}
						initialDelaySeconds: 30
						periodSeconds:       10
					}
					readinessProbe: {
						httpGet: {
							path: "/ready"
							port: 8080
						}
						initialDelaySeconds: 10
						periodSeconds:       5
					}
				}
			}
		}
	}

	#values: {
		frontend: {
			image!:    string
			apiUrl!:   string
			replicas?: int & >=1 & <=10 | *2
		}
		api: {
			image!:       string
			environment!: "development" | "staging" | "production"
			replicas?:    int & >=1 & <=20 | *3
		}
	}
}
