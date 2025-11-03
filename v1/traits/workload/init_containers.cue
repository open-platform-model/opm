package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// InitContainers Trait Definition
/////////////////////////////////////////////////////////////////

#InitContainersTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "InitContainers"
		description: "A trait to specify init containers for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: initContainers: schemas.#InitContainersSchema
})

#InitContainers: close(core.#ComponentDefinition & {
	#traits: {(#InitContainersTrait.metadata.fqn): #InitContainersTrait}
})
