package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// CronJobConfig Trait Definition
/////////////////////////////////////////////////////////////////

#CronJobConfigTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "CronJobConfig"
		description: "A trait to configure CronJob-specific settings for scheduled task workloads"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: cronJobConfig: schemas.#CronJobConfigSchema
})

#CronJobConfig: close(core.#ComponentDefinition & {
	#traits: {(#CronJobConfigTrait.metadata.fqn): #CronJobConfigTrait}
})
