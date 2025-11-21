package scopes

import (
	core "opm.dev/core@v1"
	comps "opm.dev/templates/advanced/components"
	network_policies "opm.dev/policies/network"
)

// Backend Component Definition

_backend: core.#ScopeDefinition & {
	metadata: {
		name:        "backend"
		description: "Internal backend services"
	}

	appliesTo: {
		components: [comps._web]
	}

	network_policies.#SharedNetwork

	spec: {
		sharedNetwork: {
			networkConfig: {
				dnsPolicy: "ClusterFirst"
			}
		}
	}
}
