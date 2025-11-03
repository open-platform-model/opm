package examples

import (
	core "opm.dev/core@v1"
	workload_blueprints "opm.dev/blueprints/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// StatefulWorkload Blueprint Example - PostgreSQL Database
//// Demonstrates using the StatefulWorkload blueprint
/////////////////////////////////////////////////////////////////

exampleStatefulWorkload: core.#ComponentDefinition & {
	metadata: {
		name: "postgres-stateful"
	}

	// Use the StatefulWorkload blueprint
	workload_blueprints.#StatefulWorkload

	spec: {
		statefulWorkload: {
			container: {
				name:  "postgres"
				image: "postgres:14"
				ports: {
					postgres: {
						name:       "postgres"
						targetPort: 5432
					}
				}
				env: {
					POSTGRES_DB: {
						name:  "POSTGRES_DB"
						value: "myapp"
					}
					POSTGRES_USER: {
						name:  "POSTGRES_USER"
						value: "admin"
					}
					POSTGRES_PASSWORD: {
						name:  "POSTGRES_PASSWORD"
						value: "secretpassword"
					}
				}
				resources: {
					requests: {
						cpu:    "500m"
						memory: "1Gi"
					}
					limits: {
						cpu:    "2000m"
						memory: "4Gi"
					}
				}
				volumeMounts: {
					data: {
						name:      "data"
						mountPath: "/var/lib/postgresql/data"
					}
				}
			}

			replicas: 3

			restartPolicy: "Always"

			updateStrategy: {
				type: "RollingUpdate"
				rollingUpdate: {
					maxUnavailable: 1
					partition:      0
				}
			}

			healthCheck: {
				livenessProbe: {
					exec: {
						command: ["pg_isready", "-U", "admin"]
					}
					initialDelaySeconds: 30
					periodSeconds:       10
					timeoutSeconds:      5
					failureThreshold:    3
				}
				readinessProbe: {
					exec: {
						command: ["pg_isready", "-U", "admin"]
					}
					initialDelaySeconds: 5
					periodSeconds:       10
					timeoutSeconds:      1
					failureThreshold:    3
				}
			}

			initContainers: [{
				name:  "init-db"
				image: "postgres:14"
				env: {
					PGHOST: {
						name:  "PGHOST"
						value: "localhost"
					}
				}
			}]

			serviceName: "postgres-headless"
		}

		// Route blueprint spec to unit/trait specs
		container:      statefulWorkload.container
		replicas:       statefulWorkload.replicas
		restartPolicy:  statefulWorkload.restartPolicy
		updateStrategy: statefulWorkload.updateStrategy
		healthCheck:    statefulWorkload.healthCheck
		initContainers: statefulWorkload.initContainers
	}
}
