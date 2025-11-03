package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// ResourceLimit Policy Definition
/////////////////////////////////////////////////////////////////

#ResourceLimitPolicy: close(core.#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/workload@v1"
		name:        "ResourceLimit"
		description: "Enforces resource limits for component workloads"
		target:      core.#PolicyTarget.component // Component-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: resourceLimit: schemas.#ResourceLimitSchema
})

#ResourceLimit: close(core.#ComponentDefinition & {
	#policies: {(#ResourceLimitPolicy.metadata.fqn): #ResourceLimitPolicy}
})
