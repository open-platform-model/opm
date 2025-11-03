package examples

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Example Bundle Flow: BundleDefinition → Bundle → BundleRelease
/////////////////////////////////////////////////////////////////

// Platform team creates BundleDefinition
exampleBundleDefinition: core.#BundleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/bundles/core@v1"
		name:        "FullStackApp"
		description: "Example full-stack application bundle"
	}

	// Collection of ModuleDefinitions
	#modulesDefinitions: {
		frontend: core.#ModuleDefinition & {
			metadata: {
				apiVersion:  "opm.dev/modules/core@v1"
				name:        "Frontend"
				version:     "1.0.0"
				description: "Frontend web application"
			}

			#components: {
				web: core.#ComponentDefinition & {
					metadata: name: "web-server"

					// Use helper shortcuts
					workload_units.#Container
					workload_traits.#Replicas
				}
			}

			// Value schema: Constraints only
			#values: {
				web: {
					image!:    string                // Required
					replicas?: int & >=1 & <=10 | *3 // Optional with default
				}
			}
		}

		backend: core.#ModuleDefinition & {
			metadata: {
				apiVersion:  "opm.dev/modules/core@v1"
				name:        "Backend"
				version:     "1.0.0"
				description: "Backend API service with database"
			}

			#components: {
				api: core.#ComponentDefinition & {
					metadata: name: "api-server"

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

			// Value schema: Constraints only
			#values: {
				api: {
					image!:    string               // Required
					replicas?: int & >=1 & <=5 | *2 // Optional with default
				}
				db: {
					image!:      string // Required
					volumeSize!: string // Required
				}
			}
		}
	}

	// Bundle-level value schema (aggregates module values)
	#values: {
		frontend: {
			web: {
				image!:    string
				replicas?: int & >=1 & <=10 | *3
			}
		}
		backend: {
			api: {
				image!:    string
				replicas?: int & >=1 & <=5 | *2
			}
			db: {
				image!:      string
				volumeSize!: string
			}
		}
	}
}

// CLI flattens BundleDefinition into Bundle (optimized IR)
exampleBundle: core.#Bundle & {
	metadata: {
		apiVersion:  "opm.dev/bundles/core@v1"
		name:        "FullStackApp"
		description: "Example full-stack application bundle (flattened)"
	}

	// Modules are flattened (ModuleDefinitions → Modules)
	#modules: {
		frontend: core.#Module & {
			metadata: {
				apiVersion:  "opm.dev/modules/core@v1"
				name:        "Frontend"
				version:     "1.0.0"
				description: "Frontend web application (flattened)"
			}

			// Components with concrete spec fields
			#components: {
				web: {
					metadata: name: "web-server"

					// Use helper shortcuts
					workload_units.#Container
					workload_traits.#Replicas

					spec: {
						container: {
							name:  #values.frontend.web.image
							image: "nginx:latest"
							ports: {
								http: {
									name:       "http"
									targetPort: 80
									protocol:   "TCP"
								}
							}
						}
						replicas: #values.frontend.web.replicas
					}
				}
			}

			// Value schema preserved from ModuleDefinition
			#values: {
				web: {
					image!:    string
					replicas?: int & >=1 & <=10 | *3
				}
			}
		}

		backend: core.#Module & {
			metadata: {
				apiVersion:  "opm.dev/modules/core@v1"
				name:        "Backend"
				version:     "1.0.0"
				description: "Backend API service with database (flattened)"
			}

			// Components with concrete spec fields
			#components: {
				api: {
					metadata: name: "api-server"

					// Use helper shortcuts
					workload_units.#Container
					workload_traits.#Replicas

					spec: {
						container: {
							name:  #values.backend.api.image
							image: "node:18"
							ports: {
								http: {
									name:       "http"
									targetPort: 3000
									protocol:   "TCP"
								}
							}
						}
						replicas: #values.backend.api.replicas
					}
				}

				db: {
					metadata: name: "database"

					// Use helper shortcuts
					workload_units.#Container
					storage_units.#Volumes

					spec: {
						container: {
							name:  #values.backend.db.image
							image: "postgres:14"
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
								size:         #values.backend.db.volumeSize
								accessMode:   "ReadWriteOnce"
								storageClass: "standard"
							}
						}
					}
				}
			}

			// Value schema preserved from ModuleDefinition
			#values: {
				api: {
					image!:    string
					replicas?: int & >=1 & <=5 | *2
				}
				db: {
					image!:      string
					volumeSize!: string
				}
			}
		}
	}

	// Bundle-level value schema preserved from BundleDefinition
	#values: {
		frontend: {
			web: {
				image!:    string
				replicas?: int & >=1 & <=10 | *3
			}
		}
		backend: {
			api: {
				image!:    string
				replicas?: int & >=1 & <=5 | *2
			}
			db: {
				image!:      string
				volumeSize!: string
			}
		}
	}
}

// User creates BundleRelease with concrete values
exampleBundleRelease: core.#BundleRelease & {
	metadata: {
		name: "fullstack-production"
		labels: {
			"environment": "production"
			"team":        "platform"
			"project":     "fullstack-app"
		}
	}

	// Reference the Bundle (not BundleDefinition)
	bundle: exampleBundle

	// Provide concrete values for all modules
	values: {
		frontend: {
			web: {
				image:    "myregistry.io/fullstack/frontend:v2.1.0"
				replicas: 5
			}
		}
		backend: {
			api: {
				image:    "myregistry.io/fullstack/backend:v2.1.0"
				replicas: 3
			}
			db: {
				image:      "postgres:14"
				volumeSize: "200Gi"
			}
		}
	}

	// Status would be populated by deployment system
	status: {
		phase:   "deployed"
		message: "Successfully deployed full-stack application"
	}
}
