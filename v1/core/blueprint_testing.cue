package v1

/////////////////////////////////////////////////////////////////
//// Example Blueprint Schemas
/////////////////////////////////////////////////////////////////

#StatelessWorkloadSchema: close({
	container:       #ContainerSchema
	replicas?:       #ReplicasSchema
	restartPolicy?:  string | *"Always"
	updateStrategy?: string | *"RollingUpdate"
	healthCheck?: {
		livenessProbe?: {
			httpGet?: {
				path!: string
				port!: uint & >0 & <65536
			}
			initialDelaySeconds?: uint | *0
			periodSeconds?:       uint | *10
		}
		readinessProbe?: {
			httpGet?: {
				path!: string
				port!: uint & >0 & <65536
			}
			initialDelaySeconds?: uint | *0
			periodSeconds?:       uint | *10
		}
	}
	sidecarContainers?: [#ContainerSchema]
	initContainers?: [#ContainerSchema]
})

/////////////////////////////////////////////////////////////////
//// Example Blueprint Definitions
/////////////////////////////////////////////////////////////////

#StatelessWorkloadBlueprint: close(#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/core@v1"
		name:        "StatelessWorkload"
		description: "A stateless workload with no requirement for stable identity or storage"
		labels: {
			"core.opm.dev/category":      "workload"
			"core.opm.dev/workload-type": "stateless"
		}
	}

	composedUnits: [
		#ContainerUnit,
	]

	composedTraits: [
		#ReplicasTrait,
	]

	#spec: statelessWorkload: #StatelessWorkloadSchema
})

#StatelessWorkload: close(#ComponentDefinition & {
	#blueprints: (#StatelessWorkloadBlueprint.metadata.fqn): #StatelessWorkloadBlueprint

	#Container
	#Replicas

	#spec: {
		statelessWorkload: #StatelessWorkloadSchema
		container:         statelessWorkload.container
		if statelessWorkload.replicas != _|_ {
			replicas: statelessWorkload.replicas
		}
	}
})

/////////////////////////////////////////////////////////////////
//// Example Component with Blueprint Applied
/////////////////////////////////////////////////////////////////

// exampleBlueprintComponent: #ComponentDefinition & {
// 	metadata: {
// 		name: "example-blueprint-component"
// 	}

// 	#StatelessWorkload

// 	statelessWorkload: {
// 		container: {
// 			name:  "example-container"
// 			image: "nginx:latest"
// 			ports: {
// 				http: {
// 					name:          "http"
// 					protocol:      "TCP"
// 					containerPort: 80
// 				}
// 			}
// 		}
// 		replicas: 3
// 	}
// }
