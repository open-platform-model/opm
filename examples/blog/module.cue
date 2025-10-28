package blog

import (
	opm "github.com/open-platform-model/core"
	common "github.com/open-platform-model/opm/examples/common"
)

opm.#Module

#metadata: {
	name:      "blog"
	namespace: "development"
	labels: {
		environment: "dev"
	}
	annotations: {
		"deployed.by": "developer@example.com"
		"git.commit":  "abc123"
	}
}

// Embed CatalogModule inline (for local testing)
// Note: With the OPM CLI, transformer selection is handled by the runtime
// This inline definition is kept for pure CUE validation only
#module: opm.#CatalogModule & {
	#metadata: {
		name:        "blog"
		description: "Local test configuration for blog"
		version:     "1.0.0"
	}

	// Reference the module definition
	moduleDefinition: blogAppDefinition

	// Attach renderer (developer testing locally)
	renderer: common.#KubernetesListRenderer

	provider: common.#KubernetesProvider
}

// Provide concrete test values
values: {
	frontend: {
		image: "blog-frontend:dev"
	}
	database: {
		storageSize: "5Gi"
	}
	environment: "development"
}
