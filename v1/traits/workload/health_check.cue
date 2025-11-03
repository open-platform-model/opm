package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// HealthCheck Trait Definition
/////////////////////////////////////////////////////////////////

#HealthCheckTrait: close(core.#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/workload@v1"
		name:        "HealthCheck"
		description: "A trait to specify liveness and readiness probes for a workload"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	appliesTo: [workload_units.#ContainerUnit]

	#spec: healthCheck: schemas.#HealthCheckSchema
})

#HealthCheck: close(core.#ComponentDefinition & {
	#traits: {(#HealthCheckTrait.metadata.fqn): #HealthCheckTrait}
})
