package transformers

import (
	core "opm.dev/core@v1"
	storage_resources "opm.dev/resources/storage@v1"
)

// PVCTransformer creates standalone PersistentVolumeClaims from Volume resources
#PVCTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opm.dev/providers/kubernetes/transformers@v1"
		name:        "PVCTransformer"
		description: "Creates standalone Kubernetes PersistentVolumeClaims from Volume resources"

		labels: {
			"core.opm.dev/resource-category": "storage"
			"core.opm.dev/resource-type":     "persistentvolumeclaim"
			"core.opm.dev/priority":          "5"
		}
	}

	// Required resources - Volumes MUST be present
	requiredResources: {
		"opm.dev/resources/storage@v1#Volumes": storage_resources.#VolumesResource
	}

	// No optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// No optional traits
	optionalTraits: {}

	// No required policies
	requiredPolicies: {}

	// No optional policies
	optionalPolicies: {}

	#transform: {
		#component: core.#ComponentDefinition
		#context:   core.#TransformerContext

		// Extract required Volumes resource (will be bottom if not present)
		_volumes: #component.spec.volumes

		// Generate PVC for each volume in the volumes map
		output: [
			for volumeName, volume in _volumes {
				apiVersion: "v1"
				kind:       "PersistentVolumeClaim"
				metadata: {
					name:      volume.name | *volumeName
					namespace: #context.name | *"default"
					labels: {
						"app.kubernetes.io/name":      #component.metadata.name
						"app.kubernetes.io/component": "storage"
					}
					if #component.metadata.annotations != _|_ {
						annotations: #component.metadata.annotations
					}
				}
				spec: {
					accessModes: volume.accessModes | *["ReadWriteOnce"]
					resources: {
						requests: {
							storage: volume.size
						}
					}

					if volume.storageClass != _|_ {
						storageClassName: volume.storageClass
					}

					if volume.volumeMode != _|_ {
						volumeMode: volume.volumeMode
					}

					if volume.selector != _|_ {
						selector: volume.selector
					}
				}
			},
		]
	}
}
