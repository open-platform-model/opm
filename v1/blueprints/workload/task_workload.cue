package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// TaskWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#TaskWorkloadBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v1"
		name:        "TaskWorkload"
		description: "A one-time task workload that runs to completion (Job)"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "task"
		}
	}

	composedUnits: [
		workload_units.#ContainerUnit,
	]

	composedTraits: [
		workload_traits.#RestartPolicyTrait,
		workload_traits.#JobConfigTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: taskWorkload: schemas.#TaskWorkloadSchema
})

#TaskWorkload: close(core.#ComponentDefinition & {
	#blueprints: (#TaskWorkloadBlueprint.metadata.fqn): #TaskWorkloadBlueprint

	workload_units.#Container
	workload_traits.#RestartPolicy
	workload_traits.#JobConfig
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		taskWorkload: schemas.#TaskWorkloadSchema
		container:    taskWorkload.container
		if taskWorkload.restartPolicy != _|_ {
			restartPolicy: taskWorkload.restartPolicy
		}
		if taskWorkload.jobConfig != _|_ {
			jobConfig: taskWorkload.jobConfig
		}
		if taskWorkload.sidecarContainers != _|_ {
			sidecarContainers: taskWorkload.sidecarContainers
		}
		if taskWorkload.initContainers != _|_ {
			initContainers: taskWorkload.initContainers
		}
	}
})
