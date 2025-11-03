package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// RestartPolicy Trait Definition
/////////////////////////////////////////////////////////////////

#RestartPolicyTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "RestartPolicy"
		description: "A trait to specify the restart policy for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: restartPolicy: schemas.#RestartPolicySchema
})

#RestartPolicy: close(core.#ComponentDefinition & {
	#traits: {(#RestartPolicyTrait.metadata.fqn): #RestartPolicyTrait}
})
