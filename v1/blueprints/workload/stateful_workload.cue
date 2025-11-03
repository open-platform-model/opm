package workload

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// StatefulWorkload Blueprint Definition
/////////////////////////////////////////////////////////////////

#StatefulWorkloadBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v1"
		name:        "StatefulWorkload"
		description: "A stateful workload with stable identity and persistent storage requirements"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "stateful"
		}
	}

	composedUnits: [
		workload_units.#ContainerUnit,
	]

	composedTraits: [
		workload_traits.#ReplicasTrait,
		workload_traits.#RestartPolicyTrait,
		workload_traits.#UpdateStrategyTrait,
		workload_traits.#HealthCheckTrait,
		workload_traits.#SidecarContainersTrait,
		workload_traits.#InitContainersTrait,
	]

	#spec: statefulWorkload: schemas.#StatefulWorkloadSchema
})

#StatefulWorkload: close(core.#ComponentDefinition & {
	#blueprints: (#StatefulWorkloadBlueprint.metadata.fqn): #StatefulWorkloadBlueprint

	workload_units.#Container
	workload_traits.#Replicas
	workload_traits.#RestartPolicy
	workload_traits.#UpdateStrategy
	workload_traits.#HealthCheck
	workload_traits.#SidecarContainers
	workload_traits.#InitContainers

	#spec: {
		statefulWorkload: schemas.#StatefulWorkloadSchema
		container:        statefulWorkload.container
		if statefulWorkload.replicas != _|_ {
			replicas: statefulWorkload.replicas
		}
		if statefulWorkload.restartPolicy != _|_ {
			restartPolicy: statefulWorkload.restartPolicy
		}
		if statefulWorkload.updateStrategy != _|_ {
			updateStrategy: statefulWorkload.updateStrategy
		}
		if statefulWorkload.healthCheck != _|_ {
			healthCheck: statefulWorkload.healthCheck
		}
		if statefulWorkload.sidecarContainers != _|_ {
			sidecarContainers: statefulWorkload.sidecarContainers
		}
		if statefulWorkload.initContainers != _|_ {
			initContainers: statefulWorkload.initContainers
		}
	}
})
