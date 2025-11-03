package examples

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Example Module Flow: ModuleDefinition → Module → ModuleRelease
/////////////////////////////////////////////////////////////////

// Developer creates ModuleDefinition
exampleModuleDefinition: core.#ModuleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/modules/core@v1"
		name:        "MyApp"
		version:     "1.0.0"
		description: "Example multi-tier application"
	}

	#components: {
		web: core.#ComponentDefinition & {
			metadata: name: "web-server"

			// Use helper shortcuts
			workload_units.#Container
			workload_traits.#Replicas
		}

		db: core.#ComponentDefinition & {
			metadata: name: "database"

			// Use helper shortcuts
			workload_units.#Container
			storage_units.#Volumes
		}
	}

	// Value schema: Constraints only, NO concrete values
	#values: {
		web: {
			image!:    string                // Required
			replicas?: int & >=1 & <=10 | *3 // Optional with default
		}
		db: {
			image!:      string // Required
			volumeSize!: string // Required
		}
	}
}

// CLI flattens ModuleDefinition into Module (optimized IR)
exampleModule: core.#Module & {
	metadata: {
		apiVersion:  "opm.dev/modules/core@v1"
		name:        "MyApp"
		version:     "1.0.0"
		description: "Example multi-tier application (flattened)"
	}

	// Components are flattened (Blueprints expanded if any were used)
	// In this case, already using Units + Traits directly
	#components: {
		web: {
			metadata: name: "web-server"

			// Use helper shortcuts
			workload_units.#Container
			workload_traits.#Replicas

			spec: {
				container: {
					name:  #values.web.image
					image: "nginx:latest"
					ports: {
						http: {
							name:       "http"
							targetPort: 80
							protocol:   "TCP"
						}
					}
				}
				replicas: #values.web.replicas
			}
		}

		db: {
			metadata: name: "database"

			// Use helper shortcuts
			workload_units.#Container
			storage_units.#Volumes

			spec: {
				container: {
					name:  #values.db.image
					image: "postgres:latest"
					ports: {
						db: {
							name:       "db"
							targetPort: 5432
							protocol:   "TCP"
						}
					}
				}
				volumes: dbData: {
					name: "dbData"
					persistentClaim: {
						size:         #values.db.volumeSize
						accessMode:   "ReadWriteOnce"
						storageClass: "standard"
					}
				}
			}
		}
	}

	// Value schema preserved from ModuleDefinition
	#values: {
		web: {
			image!:    string                // Required
			replicas?: int & >=1 & <=10 | *3 // Optional with default
		}
		db: {
			image!:      string // Required
			volumeSize!: string // Required
		}
	}
}

// User creates ModuleRelease with concrete values
exampleModuleRelease: core.#ModuleRelease & {
	metadata: {
		name:      "my-app-production"
		namespace: "production"
		labels: {
			"environment": "production"
			"team":        "platform"
		}
	}

	// Reference the Module (not ModuleDefinition)
	module: exampleModule

	// Provide concrete values
	values: {
		web: {
			image:    "myregistry.io/my-app/web:v1.2.3"
			replicas: 5
		}
		db: {
			image:      "postgres:14"
			volumeSize: "100Gi"
		}
	}

	// Status would be populated by deployment system
	status: {
		phase:      "deployed"
		message:    "Successfully deployed"
		deployedAt: "2025-10-30T10:00:00Z"
	}
}
