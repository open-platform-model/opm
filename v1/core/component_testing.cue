package v1

/////////////////////////////////////////////////////////////////
//// Example Component Instance
/////////////////////////////////////////////////////////////////

exampleComponent: #ComponentDefinition & {
	metadata: {
		name: "example-container-component"
	}

	// Compose units and traits using helpers
	#Container
	#Volumes
	#Replicas

	// Define concrete spec values
	spec: {
		replicas: 3
		container: {
			name:  "nginx-container"
			image: "nginx:latest"
			ports: {
				http: {
					name:          "http"
					containerPort: 80
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
			name:     "dbData"
			capacity: "10Gi"
			accessModes: ["ReadWriteOnce"]
			storageClassName: "standard"
		}
	}
}
