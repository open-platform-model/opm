package v1

/////////////////////////////////////////////////////////////////
//// Example Schemas
/////////////////////////////////////////////////////////////////

#VolumeSchema: close({
	name!:     string
	capacity!: string
	accessModes!: ["ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany"]
	storageClassName?: string
})

#VolumeMountSchema: close({
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
})

#NetworkProtocol: "TCP" | "UDP" | "ICMP" | *"TCP"
#NetworkPort:     uint & >0 & <65536
#Port: {
	name!:          string
	protocol:       #NetworkProtocol
	containerPort!: #NetworkPort
}

#ContainerSchema: close({
	name!:           string
	image!:          string
	imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
	ports?: [portName=string]: #Port
	env?: [string]: {
		name:  string
		value: string
	}
	resources?: {
		limits?: {
			cpu?:    string
			memory?: string
		}
		requests?: {
			cpu?:    string
			memory?: string
		}
	}
	volumeMounts?: [string]: {
		mountPath!: string
		subPath?:   string
		readOnly?:  bool | *false
	}
})

#ReplicasSchema: int & >=1 & <=1000 | *1

/////////////////////////////////////////////////////////////////
//// Example Unit Definitions
/////////////////////////////////////////////////////////////////

#ContainerUnit: close(#UnitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/units/workload@v1"
		name:        "Container"
		description: "A container definition for workloads"
		labels: {
			"core.opm.dev/category": "workload"
		}
	}

	// OpenAPIv3-compatible schema defining the structure of the container spec
	#spec: container: #ContainerSchema
})

#Container: close(#ComponentDefinition & {
	#units: {(#ContainerUnit.metadata.fqn): #ContainerUnit}
})

#VolumesUnit: close(#UnitDefinition & {
	metadata: {
		apiVersion:  "opm.dev/units/storage@v1"
		name:        "Volumes"
		description: "A volume definition for workloads"
		labels: {
			"core.opm.dev/category": "storage"
		}
	}

	// OpenAPIv3-compatible schema defining the structure of the volume spec
	#spec: volumes: [volumeName=string]: #VolumeSchema & {name: string | *volumeName}
})

#Volumes: close(#ComponentDefinition & {
	#units: {(#VolumesUnit.metadata.fqn): #VolumesUnit}
})
