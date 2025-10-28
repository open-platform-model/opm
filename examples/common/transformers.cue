package common

import (
	"list"

	opm "github.com/open-platform-model/core"
)

/////////////////////////////////////////////////////////////////
//// Example Transformer Implementations
/////////////////////////////////////////////////////////////////
// These are examples showing how platform-specific transformers
// could be implemented. Actual implementations would be in
// platform-specific provider packages.

// Example: Kubernetes Deployment Transformer
// Handles stateless workloads only
// Labels are used for generic matching - ALL labels must match the component
#DeploymentTransformer: opm.#Transformer & {
	#kind:       "Deployment"
	#apiVersion: "k8s.io/api/apps/v1"

	#metadata: {
		labels: {
			"core.opm.dev/workload-type": "stateless"
			// You can add more labels here for finer-grained matching
			// Example: "core.opm.dev/tier": "frontend"
			// The module will match this transformer only to components where ALL labels match
		}
	}

	// This transformer specifically handles Container primitive for stateless workloads
	required: ["elements.opm.dev/core/v0.Container"]
	optional: [
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.Replicas",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
	]

	transform: {
		#component: opm.#Component
		#context:   opm.#TransformerContext

		// Returns a list with a single Deployment resource
		output: [{
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:        #component.#metadata.name
				namespace:   #component.#metadata.namespace
				labels:      #component.#metadata.labels
				annotations: #component.#metadata.annotations
			}
			spec: {
				replicas: (#component.replicas | *{count: 1}).count
				template: {
					spec: {
						containers: list.Concat([[#component.container], #component.sidecarContainers | *[]])
						if len(#component.initContainers | *[]) > 0 {
							initContainers: #component.initContainers
						}
					}
				}
			}
		}]
	}
}

// Example: Kubernetes StatefulSet Transformer
// Handles stateful workloads only
#StatefulSetTransformer: opm.#Transformer & {
	#kind:       "StatefulSet"
	#apiVersion: "k8s.io/api/apps/v1"

	#metadata: {
		labels: {
			"core.opm.dev/workload-type": "stateful"
		}
	}

	// This transformer specifically handles Container primitive for stateful workloads
	required: ["elements.opm.dev/core/v0.Container"]
	optional: [
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.Replicas",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
		"elements.opm.dev/core/v0.Volume",
	]

	transform: {
		#component: opm.#Component
		#context:   opm.#TransformerContext

		// Returns a list with a single StatefulSet resource
		output: [{
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
			metadata: {
				name:        #component.#metadata.name
				namespace:   #component.#metadata.namespace
				labels:      #component.#metadata.labels
				annotations: #component.#metadata.annotations
			}
			spec: {
				replicas: (#component.replicas | *{count: 1}).count
				serviceName: #component.#metadata.name
				template: {
					spec: {
						containers: list.Concat([[#component.container], #component.sidecarContainers | *[]])
						if len(#component.initContainers | *[]) > 0 {
							initContainers: #component.initContainers
						}
					}
				}
				if #component.volume != _|_ {
					volumeClaimTemplates: [
						for volumeName, volumeSpec in #component.volume {
							if volumeSpec.persistentClaim != _|_ {
								metadata: {
									name: volumeName
								}
								spec: {
									accessModes: [volumeSpec.persistentClaim.accessMode]
									resources: requests: storage: volumeSpec.persistentClaim.size
									if volumeSpec.persistentClaim.storageClass != _|_ {
										storageClassName: volumeSpec.persistentClaim.storageClass
									}
								}
							}
						},
					]
				}
			}
		}]
	}
}

// Example: Kubernetes PersistentVolumeClaim Transformer
#PersistentVolumeClaimTransformer: opm.#Transformer & {
	#kind:       "PersistentVolumeClaim"
	#apiVersion: "k8s.io/api/core/v1"

	#metadata: {
		// No labels - applies to any component with Volume primitive
	}

	// This transformer specifically handles Volume primitive
	required: ["elements.opm.dev/core/v0.Volume"]
	optional: []

	transform: {
		#component: opm.#Component
		#context:   opm.#TransformerContext

		// Extract volumes - iterate directly without existence check
		// NOTE: The 'if #component.volume != _|_' check fails due to CUE evaluation order
		// See BUG_CUE_ITERATION.md for details
		output: [
			for volumeName, volumeSpec in #component.volume {
				if volumeSpec.persistentClaim != _|_ {
					apiVersion: "v1"
					kind:       "PersistentVolumeClaim"
					metadata: {
						name:        "\(#component.#metadata.name)-\(volumeName)"
						namespace:   #component.#metadata.namespace
						labels:      #component.#metadata.labels
						annotations: #component.#metadata.annotations
					}
					spec: {
						accessModes: [volumeSpec.persistentClaim.accessMode]
						resources: requests: storage: volumeSpec.persistentClaim.size
						storageClassName: volumeSpec.persistentClaim.storageClass
					}
				}
			},
		]
	}
}
