package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// SidecarContainers Trait Definition
/////////////////////////////////////////////////////////////////

#SidecarContainersTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "SidecarContainers"
		description: "A trait to specify sidecar containers for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: sidecarContainers: schemas.#SidecarContainersSchema
})

#SidecarContainers: close(core.#ComponentDefinition & {
	#traits: {(#SidecarContainersTrait.metadata.fqn): #SidecarContainersTrait}
})
