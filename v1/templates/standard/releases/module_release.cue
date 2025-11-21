package module

import (
	core "opm.dev/core@v1"
	standard "opm.dev/templates/standard@v1"
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
		name:      "standard-app-local"
		namespace: "default"
		labels: {
			"environment": "local"
			"template":    "standard"
		}
		annotations: {
			"description": "Default release for local development and testing"
		}
	}

	// Embed the module definition by referencing fields from parent package
	module: {
		apiVersion:  standard.metadata.apiVersion
		kind:        "ModuleDefinition"
		metadata:    standard.metadata
		#components: standard.#components
		#values:     standard.#values
	}

	// Concrete values matching the value schema
	// All required fields (marked with !) must be provided
	values: {
		web: {
			image:    "nginx:latest" // Satisfies web.image! requirement
			replicas: 3              // Uses default from schema (optional)
		}
		db: {
			image:      "postgres:14" // Satisfies db.image! requirement
			volumeSize: "10Gi"        // Satisfies db.volumeSize! requirement
		}
	}
}
