package schemas

/////////////////////////////////////////////////////////////////
//// Container Schemas
/////////////////////////////////////////////////////////////////

// Container specification
#ContainerSchema: {
	name!:           string
	image!:          string
	imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
	ports?: [portName=string]: #PortSchema & {name: portName}
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
	volumeMounts?: [string]: #VolumeMountSchema
}

//////////////////////////////////////////////////////////////////
//// Replicas Schema
//////////////////////////////////////////////////////////////////

#ReplicasSchema: int & >=1 & <=1000 | *1

//////////////////////////////////////////////////////////////////
//// ResourceLimit Schema
//////////////////////////////////////////////////////////////////

#ResourceLimitSchema: {
	cpu?: {
		request!: string & =~"^[0-9]+m$"
		limit!:   string & =~"^[0-9]+m$"
	}
	memory?: {
		request!: string & =~"^[0-9]+[MG]i$"
		limit!:   string & =~"^[0-9]+[MG]i$"
	}
}

//////////////////////////////////////////////////////////////////
//// RestartPolicy Schema
//////////////////////////////////////////////////////////////////

#RestartPolicySchema: "Always" | "OnFailure" | "Never" | *"Always"

//////////////////////////////////////////////////////////////////
//// UpdateStrategy Schema
//////////////////////////////////////////////////////////////////

#UpdateStrategySchema: {
	type: "RollingUpdate" | "Recreate" | "OnDelete" | *"RollingUpdate"
	if type == "RollingUpdate" {
		rollingUpdate?: {
			maxUnavailable?: uint | string | *1
			maxSurge?:       uint | string | *1
			partition?:      uint
		}
	}
}

//////////////////////////////////////////////////////////////////
//// HealthCheck Schema
//////////////////////////////////////////////////////////////////

#HealthCheckSchema: {
	livenessProbe?: {
		httpGet?: {
			path!: string
			port!: uint & >0 & <65536
		}
		exec?: {
			command!: [...string]
		}
		tcpSocket?: {
			port!: uint & >0 & <65536
		}
		initialDelaySeconds?: uint | *0
		periodSeconds?:       uint | *10
		timeoutSeconds?:      uint | *1
		successThreshold?:    uint | *1
		failureThreshold?:    uint | *3
	}
	readinessProbe?: {
		httpGet?: {
			path!: string
			port!: uint & >0 & <65536
		}
		exec?: {
			command!: [...string]
		}
		tcpSocket?: {
			port!: uint & >0 & <65536
		}
		initialDelaySeconds?: uint | *0
		periodSeconds?:       uint | *10
		timeoutSeconds?:      uint | *1
		successThreshold?:    uint | *1
		failureThreshold?:    uint | *3
	}
}

//////////////////////////////////////////////////////////////////
//// SidecarContainers Schema
//////////////////////////////////////////////////////////////////

#SidecarContainersSchema: [...#ContainerSchema]

//////////////////////////////////////////////////////////////////
//// InitContainers Schema
//////////////////////////////////////////////////////////////////

#InitContainersSchema: [...#ContainerSchema]

//////////////////////////////////////////////////////////////////
//// JobConfig Schema
//////////////////////////////////////////////////////////////////

#JobConfigSchema: {
	completions?:             uint | *1
	parallelism?:             uint | *1
	backoffLimit?:            uint | *6
	activeDeadlineSeconds?:   uint | *300
	ttlSecondsAfterFinished?: uint | *100
}

//////////////////////////////////////////////////////////////////
//// CronJobConfig Schema
//////////////////////////////////////////////////////////////////

#CronJobConfigSchema: {
	scheduleCron!:               string
	concurrencyPolicy?:          "Allow" | "Forbid" | "Replace" | *"Allow"
	startingDeadlineSeconds?:    uint
	successfulJobsHistoryLimit?: uint | *3
	failedJobsHistoryLimit?:     uint | *1
}

//////////////////////////////////////////////////////////////////
//// Stateless Workload Schema
//////////////////////////////////////////////////////////////////

#StatelessWorkloadSchema: close({
	container:          #ContainerSchema
	replicas?:          #ReplicasSchema
	restartPolicy?:     #RestartPolicySchema
	updateStrategy?:    #UpdateStrategySchema
	healthCheck?:       #HealthCheckSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
})

//////////////////////////////////////////////////////////////////
//// Stateful Workload Schema
//////////////////////////////////////////////////////////////////

#StatefulWorkloadSchema: close({
	container:          #ContainerSchema
	replicas?:          #ReplicasSchema
	restartPolicy?:     #RestartPolicySchema
	updateStrategy?:    #UpdateStrategySchema
	healthCheck?:       #HealthCheckSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
	serviceName?:       string
})

//////////////////////////////////////////////////////////////////
//// Daemon Workload Schema
//////////////////////////////////////////////////////////////////

#DaemonWorkloadSchema: close({
	container:          #ContainerSchema
	restartPolicy?:     #RestartPolicySchema
	updateStrategy?:    #UpdateStrategySchema
	healthCheck?:       #HealthCheckSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
})

//////////////////////////////////////////////////////////////////
//// Task Workload Schema
//////////////////////////////////////////////////////////////////

#TaskWorkloadSchema: close({
	container:          #ContainerSchema
	restartPolicy?:     "OnFailure" | "Never" | *"Never"
	jobConfig?:         #JobConfigSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
})

//////////////////////////////////////////////////////////////////
//// Scheduled Task Workload Schema
//////////////////////////////////////////////////////////////////

#ScheduledTaskWorkloadSchema: close({
	container:          #ContainerSchema
	restartPolicy?:     "OnFailure" | "Never" | *"Never"
	cronJobConfig!:     #CronJobConfigSchema
	sidecarContainers?: #SidecarContainersSchema
	initContainers?:    #InitContainersSchema
})
