package examples

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Basic Component Example
//// Demonstrates simple component composition with units and traits
/////////////////////////////////////////////////////////////////

exampleComponent: core.#ComponentDefinition & {
	metadata: {
		name: "example-container-component"
	}

	// Compose units and traits using helpers
	workload_units.#Container
	storage_units.#Volumes
	workload_traits.#Replicas

	// Define concrete spec values
	spec: {
		replicas: 3
		container: {
			name:  "nginx-container"
			image: "nginx:latest"
			ports: {
				http: {
					name:       "http"
					targetPort: 80
					protocol:   "TCP"
				}
			}
			env: {
				ENVIRONMENT: {
					name:  "ENVIRONMENT"
					value: "production"
				}
			}
			resources: {
				limits: {
					cpu:    "500m"
					memory: "256Mi"
				}
				requests: {
					cpu:    "250m"
					memory: "128Mi"
				}
			}
		}
		volumes: dbData: {
			name: "dbData"
			persistentClaim: {
				size:         "10Gi"
				accessMode:   "ReadWriteOnce"
				storageClass: "standard"
			}
		}
	}
}
