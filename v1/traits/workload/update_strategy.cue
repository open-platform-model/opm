package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// UpdateStrategy Trait Definition
/////////////////////////////////////////////////////////////////

#UpdateStrategyTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "UpdateStrategy"
		description: "A trait to specify the update strategy for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: updateStrategy: schemas.#UpdateStrategySchema
})

#UpdateStrategy: close(core.#ComponentDefinition & {
	#traits: {(#UpdateStrategyTrait.metadata.fqn): #UpdateStrategyTrait}
})
