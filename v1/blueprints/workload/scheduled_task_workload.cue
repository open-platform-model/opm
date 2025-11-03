package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// ScheduledTaskWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#ScheduledTaskWorkloadBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v1"
		name:        "ScheduledTaskWorkload"
		description: "A scheduled task workload that runs on a cron schedule (CronJob)"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "scheduled-task"
		}
	}

	composedUnits: [
		workload_units.#ContainerUnit,
	]

	composedTraits: [
		workload_traits.#RestartPolicyTrait,
		workload_traits.#CronJobConfigTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: scheduledTaskWorkload: schemas.#ScheduledTaskWorkloadSchema
})

#ScheduledTaskWorkload: close(core.#ComponentDefinition & {
	#blueprints: (#ScheduledTaskWorkloadBlueprint.metadata.fqn): #ScheduledTaskWorkloadBlueprint

	workload_units.#Container
	workload_traits.#RestartPolicy
	workload_traits.#CronJobConfig
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		scheduledTaskWorkload: schemas.#ScheduledTaskWorkloadSchema
		container:             scheduledTaskWorkload.container
		if scheduledTaskWorkload.restartPolicy != _|_ {
			restartPolicy: scheduledTaskWorkload.restartPolicy
		}
		cronJobConfig: scheduledTaskWorkload.cronJobConfig
		if scheduledTaskWorkload.sidecarContainers != _|_ {
			sidecarContainers: scheduledTaskWorkload.sidecarContainers
		}
		if scheduledTaskWorkload.initContainers != _|_ {
			initContainers: scheduledTaskWorkload.initContainers
		}
	}
})
