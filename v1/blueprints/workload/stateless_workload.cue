package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// StatelessWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#StatelessWorkloadBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v1"
		name:        "StatelessWorkload"
		description: "A stateless workload with no requirement for stable identity or storage"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "stateless"
		}
	}

	composedUnits: [
		workload_units.#ContainerUnit,
	]

	composedTraits: [
		workload_traits.#ReplicasTrait,
	]

	#spec: statelessWorkload: schemas.#StatelessWorkloadSchema
})

#StatelessWorkload: close(core.#ComponentDefinition & {
	#blueprints: (#StatelessWorkloadBlueprint.metadata.fqn): #StatelessWorkloadBlueprint

	workload_units.#Container
	workload_traits.#Replicas

	#spec: {
		statelessWorkload: schemas.#StatelessWorkloadSchema
		container:         statelessWorkload.container
		if statelessWorkload.replicas != _|_ {
			replicas: statelessWorkload.replicas
		}
	}
})
