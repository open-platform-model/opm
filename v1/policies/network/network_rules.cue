package network

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// NetworkRules Policy Definition
/////////////////////////////////////////////////////////////////

#NetworkRulesPolicy: close(core.#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/connectivity@v1"
		name:        "NetworkRules"
		description: "Defines network traffic rules"
		target:      core.#PolicyTarget.scope // Scope-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: networkRules: [ruleName=string]: schemas.#NetworkRuleSchema
})

#NetworkRules: close(core.#ScopeDefinition & {
	#policies: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
})
