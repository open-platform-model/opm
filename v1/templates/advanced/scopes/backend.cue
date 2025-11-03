package scopes

import (
	core "opm.dev/core@v1"
	components "template.opm.dev/components"
	network_policies "opm.dev/policies/network"
)

// Backend Component Definition

_backend: core.#ScopeDefinition & {
	metadata: name: "backend"
	description: "Internal backend services"

	appliesTo: {
		components: [components._web]
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
