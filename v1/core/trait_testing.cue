package core

/////////////////////////////////////////////////////////////////
//// Example Trait Definitions
/////////////////////////////////////////////////////////////////

#ReplicasTrait: close(#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/scaling@v1"
		name:        "Replicas"
		description: "A trait to specify the number of replicas for a workload"
		labels: {
			"core.opm.dev/trait-type": "scaling"
		}
	}

	appliesTo: [#ContainerUnit] // Full CUE reference (not FQN string)

	#spec: replicas: #ReplicasSchema
})

#Replicas: close(#ComponentDefinition & {
	#traits: {(#ReplicasTrait.metadata.fqn): #ReplicasTrait}
})

#ExposeTrait: close(#TraitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/traits/networking@v1"
		name:        "Expose"
		description: "A trait to expose a workload via a service"
		labels: {
			"core.opm.dev/trait-type": "networking"
		}
	}

	appliesTo: [#ContainerUnit] // Full CUE reference (not FQN string)

	#spec: expose: {
		type!:    "ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName" | *"ClusterIP"
		port!:    int & >=1 & <=65535
		protocol: "TCP" | "UDP" | *"TCP"
	}
})

#Expose: close(#ComponentDefinition & {
	#traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
})
