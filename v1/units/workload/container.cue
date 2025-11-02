package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
)

/////////////////////////////////////////////////////////////////
//// Container Unit Definition
/////////////////////////////////////////////////////////////////

#ContainerUnit: close(core.#UnitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/units/workload@v1"
		name:        "Container"
		description: "A container definition for workloads"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	// OpenAPIv3-compatible schema defining the structure of the container spec
	#spec: container: schemas.#ContainerSchema
})

#Container: close(core.#ComponentDefinition & {
	#units: {(#ContainerUnit.metadata.fqn): #ContainerUnit}
})
