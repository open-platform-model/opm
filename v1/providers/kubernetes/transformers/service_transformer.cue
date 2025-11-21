package transformers

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	network_traits "opm.dev/traits/network@v1"
)

// ServiceTransformer creates Kubernetes Services from components with Expose trait
#ServiceTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opm.dev/providers/kubernetes/transformers@v1"
		name:        "ServiceTransformer"
		description: "Creates Kubernetes Services for components with Expose trait"

		labels: {
			"core.opm.dev/trait-type":    "network"
			"core.opm.dev/resource-type": "service"
			"core.opm.dev/priority":      "5"
		}
	}

	// Required resources - Container MUST be present to know which ports to expose
	requiredResources: {
		"opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - Expose is mandatory for Service creation
	requiredTraits: {
		"opm.dev/traits/networking@v1#Expose": network_traits.#ExposeTrait
	}

	// No optional traits
	optionalTraits: {}

	// No required policies
	requiredPolicies: {}

	// No optional policies
	optionalPolicies: {}

	#transform: {
		#component: core.#ComponentDefinition
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Extract required Expose trait (will be bottom if not present)
		_expose: #component.spec.expose

		// Build port list from expose trait ports
		_ports: [
			for portName, portConfig in _expose.ports {
				{
					name:       portName
					port:       portConfig.port
					targetPort: portConfig.targetPort
					protocol:   portConfig.protocol | *"TCP"
					if _expose.type == "NodePort" && portConfig.exposedPort != _|_ {
						nodePort: portConfig.exposedPort
					}
				}
			},
		]

		// Build Service resource
		output: [{
			apiVersion: "v1"
			kind:       "Service"
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
				type: _expose.type

				selector: {
					app: #component.metadata.name
				}

				ports: _ports
			}
		}]
	}
}
