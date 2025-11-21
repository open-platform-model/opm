package scopes

import (
	core "opm.dev/core@v1"
	comps "opm.dev/templates/advanced/components"
	network_policies "opm.dev/policies/network"
)

// Api Component Definition

_api: core.#ScopeDefinition & {
	metadata: {
		name:        "frontend"
		description: "Frontend scope for public-facing components"
	}

	appliesTo: {
		components: [comps._web]
	}

	network_policies.#NetworkRules

	spec: {
		networkRules: {
			allowHTTP: {
				ingress: [{
					from: ["*"] // Allow from any
					ports: [{
						name:       "http"
						targetPort: 80
					}]
				}]
			}
			allowHTTPS: {
				ingress: [{
					from: ["*"] // Allow from any
					ports: [{
						name:       "https"
						targetPort: 443
					}]
				}]
			}
		}
	}
}
