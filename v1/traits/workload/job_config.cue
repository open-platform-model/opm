package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// JobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#JobConfigTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "JobConfig"
		description: "A trait to configure Job-specific settings for task workloads"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: jobConfig: schemas.#JobConfigSchema
})

#JobConfig: close(core.#ComponentDefinition & {
	#traits: {(#JobConfigTrait.metadata.fqn): #JobConfigTrait}
})
