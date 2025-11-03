package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// DaemonWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#DaemonWorkloadBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v1"
		name:        "DaemonWorkload"
		description: "A daemon workload that runs on all (or selected) nodes in a cluster"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "daemon"
		}
	}

	composedUnits: [
		workload_units.#ContainerUnit,
	]

	composedTraits: [
		workload_traits.#RestartPolicyTrait,
		workload_traits.#UpdateStrategyTrait,
		workload_traits.#HealthCheckTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: daemonWorkload: schemas.#DaemonWorkloadSchema
})

#DaemonWorkload: close(core.#ComponentDefinition & {
	#blueprints: (#DaemonWorkloadBlueprint.metadata.fqn): #DaemonWorkloadBlueprint

	workload_units.#Container
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		daemonWorkload: schemas.#DaemonWorkloadSchema
		container:      daemonWorkload.container
		if daemonWorkload.restartPolicy != _|_ {
			restartPolicy: daemonWorkload.restartPolicy
		}
		if daemonWorkload.updateStrategy != _|_ {
			updateStrategy: daemonWorkload.updateStrategy
		}
		if daemonWorkload.healthCheck != _|_ {
			healthCheck: daemonWorkload.healthCheck
		}
		if daemonWorkload.sidecarContainers != _|_ {
			sidecarContainers: daemonWorkload.sidecarContainers
		}
		if daemonWorkload.initContainers != _|_ {
			initContainers: daemonWorkload.initContainers
		}
	}
})
