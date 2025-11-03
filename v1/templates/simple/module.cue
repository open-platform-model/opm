package simple

import (
	core "opm.dev/core@v1"
	units_workload "opm.dev/units/workload@v1"
	units_storage "opm.dev/units/storage@v1"
	traits_workload "opm.dev/traits/workload@v1"
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
core.#ModuleDefinition

// Module metadata
metadata: {
	apiVersion:  "opm.dev/modules/core@v1"
	name:        "SimpleApp"
	version:     "1.0.0"
	description: "Simple web application with database"
}

// Components: Define what this module contains
#components: {
	// Example: Web server component (uncomment and customize)
	web: {
		// Compose component from units and traits using helper shortcuts
		// CUE automatically unifies these into the component definition
		units_workload.#Container // Adds container unit (workload type)

		traits_workload.#Replicas // Adds replicas trait (scaling behavior)

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

	// Example: Database component (uncomment and customize)
	db: {
		// Compose component from units
		units_workload.#Container // Adds container unit

		units_storage.#Volumes // Adds volumes unit (persistent storage)

		spec: {
			container: {
				name:  #values.db.image  // Use image from values
				image: "postgres:latest" // Customize with your database image
				ports: {
					dbPort: {
						name:       "db-port"
						targetPort: 5432
					}
				}
			}
			volumes: {
				dataVolume: {
					name: "data-volume"
					persistentClaim: {
						size:         #values.db.volumeSize // Use volumeSize from values
						accessMode:   "ReadWriteOnce"
						storageClass: "standard"
					}
				}
			}
		}
	}
}

// Value Schema: Defines constraints for configuration values
// These are NOT concrete values - concrete values are provided at deployment time
#values: {
	// Example: Web server configuration (uncomment and customize)
	web: {
		// Required field: container image
		image!: string

		// Optional field: number of replicas (default: 3)
		// Constraints: must be between 1 and 10
		replicas?: int & >=1 & <=10 | *3
	}

	// Example: Database configuration (uncomment and customize)
	db: {
		// Required field: container image
		image!: string

		// Required field: persistent volume size
		volumeSize!: string
	}
}
