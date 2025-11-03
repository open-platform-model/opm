package network

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// SharedNetwork Policy Definition
/////////////////////////////////////////////////////////////////

#SharedNetworkPolicy: close(core.#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/connectivity@v1"
		name:        "SharedNetwork"
		description: "Allows all network traffic between components in the same scope based on their exposed ports"
		target:      core.#PolicyTarget.scope // Scope-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: sharedNetwork: schemas.#SharedNetworkSchema
})

#SharedNetwork: close(core.#ScopeDefinition & {
	#policies: {(#SharedNetworkPolicy.metadata.fqn): #SharedNetworkPolicy}
})
