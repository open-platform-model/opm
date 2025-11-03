package standard

import (
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// Component Definitions
// =====================

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
