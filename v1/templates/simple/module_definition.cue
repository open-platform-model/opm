package simple

import (
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Simple Template: Everything in One File
// ========================================
// This template is perfect for:
// - Learning OPM
// - Simple applications (1-3 components)
// - Quick prototypes and demos
//
// All configuration is in this single file: ModuleDefinition, components, and values.

// Declare this as a ModuleDefinition
apiVersion: "opm.dev/v1/core"
kind:       "ModuleDefinition"

metadata: {
	apiVersion:  "example.com/modules/simple@v1"
	name:        "simple-module"
	version:     "v0.1.0"
	description: "A simple OPM module"
}

// Define components
#components: {
	// Example: Uncomment and modify to add a stateless workload
	web: {
		// Compose component from resources and traits using helper shortcuts
		// CUE automatically unifies these into the component definition
		workload_resources.#Container // Adds container unit (workload type)

		workload_traits.#Replicas // Adds replicas trait (scaling behavior)

		spec: {
			container: {
				name:  #values.web.image // Use image from values
				image: "nginx:latest"    // Customize with your web server image
				ports: {
					http: {
						name:       "http"
						targetPort: 80
					}
				}
			}
			replicas: #values.web.replicas // Use replicas from values
		}
	}
}

// Define value schema
#values: {
	// Example: Web server configuration (uncomment and customize)
	web: {
		// Required field: container image
		image!: string

		// Optional field: number of replicas (default: 3)
		// Constraints: must be between 1 and 10
		replicas?: int & >=1 & <=10 | *3
	}
}
