package supabase

import (
	opm "github.com/open-platform-model/core"
	common "github.com/open-platform-model/opm/examples/common"
)

opm.#Module

#metadata: {
	name:      "supabase-app"
	namespace: "development"
	labels: {
		environment: "dev"
	}
	annotations: {
		"deployed.by": "developer@example.com"
		"git.commit":  "local-dev"
	}
}

// Embed CatalogModule inline (for local testing)
// Note: With the OPM CLI, transformer selection is handled by the runtime
// This inline definition is kept for pure CUE validation only
#module: opm.#CatalogModule & {
	#metadata: {
		name:        "supabase-app-local"
		description: "Local test configuration for supabase app"
		version:     "1.0.0"
	}

	// Reference the module definition
	moduleDefinition: supabaseAppDefinition

	// Attach renderer (developer testing locally)
	renderer: common.#KubernetesListRenderer

	provider: common.#KubernetesProvider
}

// Provide concrete test values
values: {
	database: {
		password:    "your-super-secret-and-long-postgres-password"
		storageSize: "10Gi"
	}
	jwt: {
		secret:     "your-super-secret-jwt-token-with-at-least-32-characters-long"
		anonKey:    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
		serviceKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"
	}
	auth: {
		siteUrl:   "http://localhost:3000"
		allowList: "http://localhost:3000,http://localhost:8000"
	}
	studio: {
		publicUrl: "http://localhost:8000"
	}
	environment: "development"
}
