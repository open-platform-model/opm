package simple

import (
	workload_blueprints "opmodel.dev/blueprints/workload@v1"
)

// Simple 2-component web application using blueprints
// This represents a ModuleDefinition where components reference blueprints
simpleModuleDefinition: {
	apiVersion: "opmodel.dev/v1/core"
	kind:       "ModuleDefinition"

	metadata: {
		apiVersion:       "opmodel.dev/benchmarks/simple@v0"
		name:             "SimpleWebApp"
		version:          "1.0.0"
		description:      "Simple web application with frontend and API backend (blueprint-based)"
		defaultNamespace: ""
	}

	#components: {
		frontend: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "web-frontend"
				labels: {
					"app.opmodel.dev/tier": "frontend"
				}
			}

			spec: statelessWorkload: {
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

		api: {
			workload_blueprints.#StatelessWorkload
			metadata: {
				name: "api-backend"
				labels: {
					"app.opmodel.dev/tier": "backend"
				}
			}

			spec: statelessWorkload: {
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
