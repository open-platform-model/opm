package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// Replicas Trait Definition
/////////////////////////////////////////////////////////////////

#ReplicasTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/scaling@v1"
		name:        "Replicas"
		description: "A trait to specify the number of replicas for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit] // Full CUE reference (not FQN string)

	#spec: replicas: schemas.#ReplicasSchema
})

#Replicas: close(core.#ComponentDefinition & {
	#traits: {(#ReplicasTrait.metadata.fqn): #ReplicasTrait}
})
