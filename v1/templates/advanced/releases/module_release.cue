package module

import (
	core "opm.dev/core@v1"
	advanced "opm.dev/templates/advanced@v1"
)

// Default ModuleRelease for local development/testing
// ====================================================
// This provides concrete values for the module's value schema.
// You can create additional release files for different environments:
// - prod.release.cue for production
// - staging.release.cue for staging
// - dev.release.cue for development
//
// Each release binds the module definition with concrete configuration values.

core.#ModuleRelease & {
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name:      "advanced-app-local"
		namespace: "default"
		labels: {
			"environment": "local"
			"template":    "advanced"
		}
		annotations: {
			"description": "Default release for local development and testing"
		}
	}

	// Embed the module definition by referencing fields from parent package
	module: {
		apiVersion:  advanced.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    advanced.metadata
		#components: advanced.#components
		#values:     advanced.#values

		// Conditionally include scopes if they exist
		if advanced.#scopes != _|_ {
			#scopes: advanced.#scopes
		}
	}

	// Concrete values matching the value schema
	// All required fields (marked with !) must be provided
	// Optional fields can use defaults from schema or be explicitly set
	values: {
		// Frontend web server
		web: {
			image:    "nginx:latest" // Required field
			replicas: 3              // Optional (uses default)
			port:     80             // Optional (uses default)
			resources: {
				cpu:    "100m"  // Optional (uses default)
				memory: "128Mi" // Optional (uses default)
			}
		}

		// Backend API service
		api: {
			image:    "myapp/api:v1.0.0" // Required field
			replicas: 5                  // Optional (uses default)
			port:     8080               // Optional (uses default)
			resources: {
				cpu:    "500m"  // Optional (uses default)
				memory: "512Mi" // Optional (uses default)
			}
			rateLimit: {
				enabled:        true // Optional (uses default)
				requestsPerMin: 1000 // Optional (uses default)
			}
		}

		// Background worker service
		worker: {
			image:    "myapp/worker:v1.0.0" // Required field
			replicas: 2                     // Optional (uses default)
			jobQueue: {
				maxConcurrent: 5    // Optional (uses default)
				timeout:       "5m" // Optional (uses default)
			}
			resources: {
				cpu:    "250m"  // Optional (uses default)
				memory: "256Mi" // Optional (uses default)
			}
		}

		// Database service
		db: {
			image:        "postgres:14" // Required field
			volumeSize:   "50Gi"        // Required field
			storageClass: "standard"    // Optional (uses default)
			backup: {
				enabled:   true        // Optional (uses default)
				schedule:  "0 2 * * *" // Optional (uses default - daily at 2 AM)
				retention: 7           // Optional (uses default - 7 days)
			}
			resources: {
				cpu:    "1000m" // Optional (uses default)
				memory: "2Gi"   // Optional (uses default)
			}
		}
	}
}
