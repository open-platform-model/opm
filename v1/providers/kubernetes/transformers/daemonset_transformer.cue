package transformers

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
	"list"
)

// DaemonSetTransformer converts daemon workload components to Kubernetes DaemonSets
#DaemonSetTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "transformer.opm.dev/workload@v1"
		name:        "DaemonSetTransformer"
		description: "Converts daemon workload components to Kubernetes DaemonSets"

		labels: {
			"core.opm.dev/workload-type": "daemon"
			"core.opm.dev/resource-type": "daemonset"
			"core.opm.dev/priority":      "10"
		}
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance daemonset behavior
	// Note: NO Replicas trait - DaemonSets run one pod per node
	optionalTraits: {
		"opm.dev/traits/workload@v1#RestartPolicy":      workload_traits.#RestartPolicyTrait
		"opm.dev/traits/workload@v1#UpdateStrategy":     workload_traits.#UpdateStrategyTrait
		"opm.dev/traits/workload@v1#HealthCheck":        workload_traits.#HealthCheckTrait
		"opm.dev/traits/workload@v1#SidecarContainers":  workload_traits.#SidecarContainersTrait
		"opm.dev/traits/workload@v1#InitContainers":     workload_traits.#InitContainersTrait
	}

	// No required policies
	requiredPolicies: {}

	// No optional policies
	optionalPolicies: {}

	#transform: {
		#component: core.#ComponentDefinition
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Apply defaults for optional traits
		_restartPolicy: *optionalTraits["opm.dev/traits/workload@v1#RestartPolicy"].#defaults | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Extract update strategy with defaults
		_updateStrategy: *null | {
			if #component.spec.updateStrategy != _|_ {
				type: #component.spec.updateStrategy.type
				if #component.spec.updateStrategy.type == "RollingUpdate" {
					rollingUpdate: #component.spec.updateStrategy.rollingUpdate
				}
			}
		}

		// Build container list (main container + optional sidecars)
		_sidecarContainers: *optionalTraits["opm.dev/traits/workload@v1#SidecarContainers"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_containers: list.Concat([
			[_container],
			_sidecarContainers,
		])

		// Extract init containers with defaults
		_initContainers: *optionalTraits["opm.dev/traits/workload@v1#InitContainers"].#defaults | [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		// Build DaemonSet resource
		output: [{
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.name | *"default"
				labels: {
					app:                      #component.metadata.name
					"app.kubernetes.io/name": #component.metadata.name
					if #component.metadata.labels != _|_ {
						for k, v in #component.metadata.labels {
							"\(k)": v
						}
					}
				}
				if #component.metadata.annotations != _|_ {
					annotations: #component.metadata.annotations
				}
			}
			spec: {
				selector: matchLabels: {
					app: #component.metadata.name
				}
				template: {
					metadata: labels: {
						app:                      #component.metadata.name
						"app.kubernetes.io/name": #component.metadata.name
					}
					spec: {
						containers: _containers

						if len(_initContainers) > 0 {
							initContainers: _initContainers
						}

						restartPolicy: _restartPolicy
					}
				}

				if _updateStrategy != null {
					updateStrategy: _updateStrategy
				}
			}
		}]
	}
}
