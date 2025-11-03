package network

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Expose Trait Definition
/////////////////////////////////////////////////////////////////

#ExposeTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/networking@v1"
		name:        "Expose"
		description: "A trait to expose a workload via a service"
		labels: {
			"core.opm.dev/category": "networking"
		}
	}

	appliesTo: [workload_units.#ContainerUnit] // Full CUE reference (not FQN string)

	#spec: expose: schemas.#ExposeSchema
})

#Expose: close(core.#ComponentDefinition & {
	#traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
})
