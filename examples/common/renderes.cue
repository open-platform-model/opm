package common

import (
	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Generic Renderers
/////////////////////////////////////////////////////////////////

// Kubernetes List Renderer
#KubernetesListRenderer: opm.#Renderer & {
	#metadata: {
		name:        "kubernetes-list"
		description: "Renders to Kubernetes List format"
		version:     "1.0.0"
		labels: {
			"core.opm.dev/format": "kubernetes"
		}
	}
	targetPlatform: "kubernetes"

	// Render function - resources will be provided by Module
	render: {
		// Input: list of Kubernetes resources
		resources: _

		// Output: single manifest in Kubernetes List format
		output: {
			// For now, return raw structure - will add YAML marshaling later
			manifest: {
				apiVersion: "v1"
				kind:       "List"
				items:      resources
			}
			metadata: {
				format: "yaml"
			}
		}
	}
}
