// Benchmark Elements Package
// Simplified element definitions for benchmarking (copied from github.com/open-platform-model/elements/core)
package elements

import (
	opm "github.com/open-platform-model/core/v0"
)

/////////////////////////////////////////////////////////////////
//// Container Schemas
/////////////////////////////////////////////////////////////////

#IANA_SVC_NAME: string

#PortSpec: {
	name!:       #IANA_SVC_NAME
	targetPort!: int & >=1 & <=65535
	protocol:    *"TCP" | "UDP" | "SCTP"
	hostIP?:     string
	hostPort?:   int & >=1 & <=65535
	...
}

#VolumeSpec: {
	name!: string
	persistentClaim?: {
		accessMode:    string | *"ReadWriteOnce"
		size!:         string
		storageClass?: string
	}
	emptyDir?: {
		sizeLimit?: string
	}
	...
}

#VolumeMountSpec: {
	name!:      string
	mountPath!: string
	subPath?:   string
	readOnly?:  bool | *false
}

#ContainerSpec: {
	name!:           string
	image!:          string
	imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
	ports?: [portName=string]: #PortSpec & {name: portName}
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
	volumeMounts?: [string]: #VolumeMountSpec
	...
}

/////////////////////////////////////////////////////////////////
//// Container Element (Primitive)
/////////////////////////////////////////////////////////////////

#ContainerElement: opm.#Primitive & {
	name:        "Container"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:      #ContainerSpec
	description: "A container definition for workloads"
	labels: {
		"core.opm.dev/category": "workload"
	}
}

#Container: opm.#Component & {
	#elements: (#ContainerElement.#fullyQualifiedName): #ContainerElement
	container: #ContainerSpec
}

/////////////////////////////////////////////////////////////////
//// Replicas Element (Modifier)
/////////////////////////////////////////////////////////////////

#ReplicasSpec: {
	count: int | *1
}

#ReplicasElement: opm.#Modifier & {
	name:        "Replicas"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:   #ReplicasSpec
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Number of desired replicas"
	labels: {"core.opm.dev/category": "workload"}
}

#Replicas: opm.#Component & {
	#elements: (#ReplicasElement.#fullyQualifiedName): #ReplicasElement
	replicas: #ReplicasSpec
}

/////////////////////////////////////////////////////////////////
//// RestartPolicy Element (Modifier)
/////////////////////////////////////////////////////////////////

#RestartPolicySpec: {
	policy: "Always" | "OnFailure" | "Never" | *"Always"
}

#RestartPolicyElement: opm.#Modifier & {
	name:        "RestartPolicy"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:   #RestartPolicySpec
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Restart policy for containers"
	labels: {"core.opm.dev/category": "workload"}
}

#RestartPolicy: opm.#Component & {
	#elements: (#RestartPolicyElement.#fullyQualifiedName): #RestartPolicyElement
	restartPolicy: #RestartPolicySpec
}

/////////////////////////////////////////////////////////////////
//// UpdateStrategy Element (Modifier)
/////////////////////////////////////////////////////////////////

#UpdateStrategySpec: {
	type: "RollingUpdate" | "Recreate" | *"RollingUpdate"
	rollingUpdate?: {
		maxUnavailable?: int | string
		maxSurge?:       int | string
	}
}

#UpdateStrategyElement: opm.#Modifier & {
	name:        "UpdateStrategy"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:   #UpdateStrategySpec
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Update strategy for workloads"
	labels: {"core.opm.dev/category": "workload"}
}

#UpdateStrategy: opm.#Component & {
	#elements: (#UpdateStrategyElement.#fullyQualifiedName): #UpdateStrategyElement
	updateStrategy: #UpdateStrategySpec
}

/////////////////////////////////////////////////////////////////
//// HealthCheck Element (Modifier)
/////////////////////////////////////////////////////////////////

#HealthCheckSpec: {
	liveness?: {
		httpGet?: {
			path:   string
			port:   int
			scheme: "HTTP" | "HTTPS" | *"HTTP"
		}
		tcpSocket?: {
			port: int
		}
		exec?: {
			command: [...string]
		}
		initialDelaySeconds?: int
		periodSeconds?:       int
		timeoutSeconds?:      int
		successThreshold?:    int
		failureThreshold?:    int
	}
	readiness?: {
		httpGet?: {
			path:   string
			port:   int
			scheme: "HTTP" | "HTTPS" | *"HTTP"
		}
		tcpSocket?: {
			port: int
		}
		exec?: {
			command: [...string]
		}
		initialDelaySeconds?: int
		periodSeconds?:       int
		timeoutSeconds?:      int
		successThreshold?:    int
		failureThreshold?:    int
	}
}

#HealthCheckElement: opm.#Modifier & {
	name:        "HealthCheck"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:   #HealthCheckSpec
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Health check probes for containers"
	labels: {"core.opm.dev/category": "workload"}
}

#HealthCheck: opm.#Component & {
	#elements: (#HealthCheckElement.#fullyQualifiedName): #HealthCheckElement
	healthCheck: #HealthCheckSpec
}

/////////////////////////////////////////////////////////////////
//// SidecarContainers Element (Modifier)
/////////////////////////////////////////////////////////////////

#SidecarContainersElement: opm.#Modifier & {
	name:        "SidecarContainers"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: [...#ContainerSpec]
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Sidecar containers for workloads"
	labels: {"core.opm.dev/category": "workload"}
}

#SidecarContainers: opm.#Component & {
	#elements: (#SidecarContainersElement.#fullyQualifiedName): #SidecarContainersElement
	sidecarContainers: [...#ContainerSpec]
}

/////////////////////////////////////////////////////////////////
//// InitContainers Element (Modifier)
/////////////////////////////////////////////////////////////////

#InitContainersElement: opm.#Modifier & {
	name:        "InitContainers"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: [...#ContainerSpec]
	modifies: ["elements.opm.dev/core/v0.Container"]
	description: "Init containers for workloads"
	labels: {"core.opm.dev/category": "workload"}
}

#InitContainers: opm.#Component & {
	#elements: (#InitContainersElement.#fullyQualifiedName): #InitContainersElement
	initContainers: [...#ContainerSpec]
}

/////////////////////////////////////////////////////////////////
//// Volume Element (Primitive)
/////////////////////////////////////////////////////////////////

#VolumeElement: opm.#Primitive & {
	name:        "Volume"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:      [string]: #VolumeSpec
	description: "Storage volumes for workloads"
	labels: {"core.opm.dev/category": "data"}
}

#Volume: opm.#Component & {
	#elements: (#VolumeElement.#fullyQualifiedName): #VolumeElement
	volume: [string]: #VolumeSpec
}

/////////////////////////////////////////////////////////////////
//// ConfigMap Element (Primitive)
/////////////////////////////////////////////////////////////////

#ConfigMapSpec: {
	data: [string]: string
}

#ConfigMapElement: opm.#Primitive & {
	name:        "ConfigMap"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:      #ConfigMapSpec
	description: "Configuration data for applications"
	labels: {"core.opm.dev/category": "data"}
}

#ConfigMap: opm.#Component & {
	#elements: (#ConfigMapElement.#fullyQualifiedName): #ConfigMapElement
	configMap: #ConfigMapSpec
}

/////////////////////////////////////////////////////////////////
//// Secret Element (Primitive)
/////////////////////////////////////////////////////////////////

#SecretSpec: {
	data: [string]: string
}

#SecretElement: opm.#Primitive & {
	name:        "Secret"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema:      #SecretSpec
	description: "Sensitive data for applications"
	labels: {"core.opm.dev/category": "data"}
}

#Secret: opm.#Component & {
	#elements: (#SecretElement.#fullyQualifiedName): #SecretElement
	secret: #SecretSpec
}

/////////////////////////////////////////////////////////////////
//// StatelessWorkload Element (Composite)
/////////////////////////////////////////////////////////////////

#StatelessSpec: {
	container:           #ContainerSpec
	replicas?:           #ReplicasSpec
	restartPolicy?:      #RestartPolicySpec
	updateStrategy?:     #UpdateStrategySpec
	healthCheck?:        #HealthCheckSpec
	sidecarContainers?: [...#ContainerSpec]
	initContainers?: [...#ContainerSpec]
}

#StatelessWorkloadElement: opm.#Composite & {
	name:        "StatelessWorkload"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #StatelessSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.Replicas",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
	]
	description: "A stateless workload with no requirement for stable identity or storage"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "stateless"
	}
}

#StatelessWorkload: opm.#Component & {
	#elements: (#StatelessWorkloadElement.#fullyQualifiedName): #StatelessWorkloadElement

	#Container
	#SidecarContainers
	#InitContainers
	#Replicas
	#RestartPolicy
	#UpdateStrategy
	#HealthCheck

	statelessWorkload: #StatelessSpec

	container: statelessWorkload.container
	if statelessWorkload.sidecarContainers != _|_ {
		sidecarContainers: statelessWorkload.sidecarContainers
	}
	if statelessWorkload.initContainers != _|_ {
		initContainers: statelessWorkload.initContainers
	}
	if statelessWorkload.replicas != _|_ {
		replicas: statelessWorkload.replicas
	}
	if statelessWorkload.restartPolicy != _|_ {
		restartPolicy: statelessWorkload.restartPolicy
	}
	if statelessWorkload.updateStrategy != _|_ {
		updateStrategy: statelessWorkload.updateStrategy
	}
	if statelessWorkload.healthCheck != _|_ {
		healthCheck: statelessWorkload.healthCheck
	}
}

/////////////////////////////////////////////////////////////////
//// StatefulWorkload Element (Composite)
/////////////////////////////////////////////////////////////////

#StatefulSpec: {
	container:           #ContainerSpec
	replicas?:           #ReplicasSpec
	restartPolicy?:      #RestartPolicySpec
	updateStrategy?:     #UpdateStrategySpec
	healthCheck?:        #HealthCheckSpec
	sidecarContainers?: [...#ContainerSpec]
	initContainers?: [...#ContainerSpec]
}

#StatefulWorkloadElement: opm.#Composite & {
	name:        "StatefulWorkload"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #StatefulSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.SidecarContainers",
		"elements.opm.dev/core/v0.InitContainers",
		"elements.opm.dev/core/v0.Replicas",
		"elements.opm.dev/core/v0.RestartPolicy",
		"elements.opm.dev/core/v0.UpdateStrategy",
		"elements.opm.dev/core/v0.HealthCheck",
	]
	description: "A stateful workload with stable identity and storage"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "stateful"
	}
}

#StatefulWorkload: opm.#Component & {
	#elements: (#StatefulWorkloadElement.#fullyQualifiedName): #StatefulWorkloadElement

	#Container
	#SidecarContainers
	#InitContainers
	#Replicas
	#RestartPolicy
	#UpdateStrategy
	#HealthCheck
	#Volume

	statefulWorkload: #StatefulSpec

	container: statefulWorkload.container
	if statefulWorkload.sidecarContainers != _|_ {
		sidecarContainers: statefulWorkload.sidecarContainers
	}
	if statefulWorkload.initContainers != _|_ {
		initContainers: statefulWorkload.initContainers
	}
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
}

/////////////////////////////////////////////////////////////////
//// TaskWorkload Element (Composite)
/////////////////////////////////////////////////////////////////

#TaskSpec: {
	container:      #ContainerSpec
	restartPolicy?: #RestartPolicySpec
}

#TaskWorkloadElement: opm.#Composite & {
	name:        "TaskWorkload"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #TaskSpec
	composes: [
		"elements.opm.dev/core/v0.Container",
		"elements.opm.dev/core/v0.RestartPolicy",
	]
	description: "A task workload that runs to completion"
	labels: {
		"core.opm.dev/category":      "workload"
		"core.opm.dev/workload-type": "task"
	}
}

#TaskWorkload: opm.#Component & {
	#elements: (#TaskWorkloadElement.#fullyQualifiedName): #TaskWorkloadElement

	#Container
	#RestartPolicy

	taskWorkload: #TaskSpec

	container: taskWorkload.container
	if taskWorkload.restartPolicy != _|_ {
		restartPolicy: taskWorkload.restartPolicy
	}
}

/////////////////////////////////////////////////////////////////
//// SimpleDatabase Element (Composite - 2-level nesting)
/////////////////////////////////////////////////////////////////

#SimpleDatabaseSpec: {
	engine:   "postgres" | "mysql" | "mongodb" | "redis" | *"postgres"
	version:  string
	dbName:   string
	username: string
	password: string
	persistence: {
		enabled:       bool | *true
		size:          string
		storageClass?: string
	}
}

#SimpleDatabaseElement: opm.#Composite & {
	name:        "SimpleDatabase"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #SimpleDatabaseSpec
	composes: [
		"elements.opm.dev/core/v0.StatefulWorkload",
		"elements.opm.dev/core/v0.Volume",
	]
	description: "A simple database with stateful workload and persistent storage"
	labels: {
		"core.opm.dev/category":      "data"
		"core.opm.dev/workload-type": "stateful"
	}
}

#SimpleDatabase: opm.#Component & {
	#elements: (#SimpleDatabaseElement.#fullyQualifiedName): #SimpleDatabaseElement

	#StatefulWorkload
	#Volume

	simpleDatabase: #SimpleDatabaseSpec

	statefulWorkload: #StatefulSpec & {
		container: #ContainerSpec & {
			if simpleDatabase.engine == "postgres" {
				name:  "database"
				image: "postgres:\(simpleDatabase.version)"
				ports: {
					db: {
						name:       "db"
						targetPort: 5432
					}
				}
				env: {
					DB_NAME: {
						name:  "DB_NAME"
						value: simpleDatabase.dbName
					}
					DB_USER: {
						name:  "DB_USER"
						value: simpleDatabase.username
					}
					DB_PASSWORD: {
						name:  "DB_PASSWORD"
						value: simpleDatabase.password
					}
				}
				if simpleDatabase.persistence.enabled {
					volumeMounts: dbData: #VolumeMountSpec & {
						name:      "dbData"
						mountPath: "/var/lib/postgresql/data"
					}
				}
			}
			if simpleDatabase.engine == "mysql" {
				name:  "database"
				image: "mysql:\(simpleDatabase.version)"
				ports: {
					db: {
						name:       "db"
						targetPort: 3306
					}
				}
				env: {
					DB_NAME: {
						name:  "DB_NAME"
						value: simpleDatabase.dbName
					}
					DB_USER: {
						name:  "DB_USER"
						value: simpleDatabase.username
					}
					DB_PASSWORD: {
						name:  "DB_PASSWORD"
						value: simpleDatabase.password
					}
				}
			}
		}
		restartPolicy: #RestartPolicySpec & {
			policy: "Always"
		}
		updateStrategy: #UpdateStrategySpec & {
			type: "RollingUpdate"
		}
		healthCheck: #HealthCheckSpec & {
			liveness: {
				httpGet: {
					path:   "/healthz"
					port:   5432
					scheme: "HTTP"
				}
			}
		}
	}

	volume: [string]: #VolumeSpec
	if simpleDatabase.persistence.enabled {
		volume: dbData: {
			name: "db-data"
			persistentClaim: {
				accessMode: "ReadWriteOnce"
				size:       simpleDatabase.persistence.size
				if simpleDatabase.persistence.storageClass != _|_ {
					storageClass: simpleDatabase.persistence.storageClass
				}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Level 4 Composites - Maximum Nesting Depth
/////////////////////////////////////////////////////////////////

// MicroserviceStack - Level 4 composite (most deeply nested)
// This composes Level 3 (SimpleDatabase) + Level 2 (StatelessWorkload) + Level 0 (ConfigMap, Secret)
// Demonstrates maximum nesting complexity for benchmarking
#MicroserviceStackSpec: {
	serviceName:  string
	serviceImage: string
	servicePort:  int

	// Database configuration (uses SimpleDatabase - Level 3)
	database: {
		engine:   "postgres" | "mysql" | *"postgres"
		version:  string | *"15"
		dbName:   string
		username: string
		password: string
		size:     string | *"100Gi"
	}

	// Service configuration (uses StatelessWorkload - Level 2)
	service: {
		replicas: int | *3
		healthCheck?: {
			path: string | *"/health"
			port: int | *8080
		}
	}

	// Configuration data (uses ConfigMap - Level 0)
	config: [string]: string

	// Secrets data (uses Secret - Level 0)
	secrets: [string]: string
}

#MicroserviceStackElement: opm.#Composite & {
	name:        "MicroserviceStack"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #MicroserviceStackSpec

	// Composes Level 3, Level 2, and Level 0 elements
	composes: [
		"elements.opm.dev/core/v0.SimpleDatabase",   // Level 3
		"elements.opm.dev/core/v0.StatelessWorkload", // Level 2
		"elements.opm.dev/core/v0.ConfigMap",        // Level 0
		"elements.opm.dev/core/v0.Secret",           // Level 0
	]

	description: "Complete microservice stack with database, service, config, and secrets (4-level nesting)"
	labels: {
		"core.opm.dev/category":      "composite"
		"core.opm.dev/nesting-level": "4"
	}
}

#MicroserviceStack: opm.#Component & {
	#elements: (#MicroserviceStackElement.#fullyQualifiedName): #MicroserviceStackElement

	#SimpleDatabase
	#StatelessWorkload
	#ConfigMap
	#Secret

	microserviceStack: #MicroserviceStackSpec

	// Map to SimpleDatabase
	simpleDatabase: #SimpleDatabaseSpec & {
		engine:   microserviceStack.database.engine
		version:  microserviceStack.database.version
		dbName:   microserviceStack.database.dbName
		username: microserviceStack.database.username
		password: microserviceStack.database.password
		persistence: {
			enabled: true
			size:    microserviceStack.database.size
		}
	}

	// Map to StatelessWorkload
	statelessWorkload: #StatelessSpec & {
		container: {
			name:  microserviceStack.serviceName
			image: microserviceStack.serviceImage
			ports: {
				http: {
					name:       "http"
					targetPort: microserviceStack.servicePort
					protocol:   "TCP"
				}
			}
			env: {
				DB_HOST: {
					name:  "DB_HOST"
					value: "localhost"
				}
			}
		}
		replicas: {
			count: microserviceStack.service.replicas
		}
		if microserviceStack.service.healthCheck != _|_ {
			healthCheck: {
				liveness: {
					httpGet: {
						path:   microserviceStack.service.healthCheck.path
						port:   microserviceStack.service.healthCheck.port
						scheme: "HTTP"
					}
				}
			}
		}
	}

	// Map to ConfigMap
	configMap: {
		data: microserviceStack.config
	}

	// Map to Secret
	secret: {
		data: microserviceStack.secrets
	}
}

/////////////////////////////////////////////////////////////////
//// WebApplicationStack - Level 4 composite (alternative design)
/////////////////////////////////////////////////////////////////

#WebApplicationStackSpec: {
	appName:     string
	appVersion:  string
	environment: "dev" | "staging" | "prod" | *"prod"

	// Frontend (uses StatelessWorkload - Level 2)
	frontend: {
		image:    string
		replicas: int | *3
	}

	// Backend (uses StatelessWorkload - Level 2)
	backend: {
		image:    string
		replicas: int | *5
	}

	// Database (uses SimpleDatabase - Level 3)
	database: {
		engine:   "postgres" | "mysql" | *"postgres"
		version:  string | *"15"
		size:     string | *"200Gi"
		dbName:   string
		username: string
		password: string
	}

	// Cache (uses StatefulWorkload - Level 2)
	cache: {
		enabled:  bool | *true
		replicas: int | *3
		size:     string | *"10Gi"
	}

	config: [string]: string
}

#WebApplicationStackElement: opm.#Composite & {
	name:        "WebApplicationStack"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #WebApplicationStackSpec

	// Composes multiple Level 3 and Level 2 elements
	composes: [
		"elements.opm.dev/core/v0.SimpleDatabase",     // Level 3
		"elements.opm.dev/core/v0.StatelessWorkload",  // Level 2 (used twice - frontend & backend)
		"elements.opm.dev/core/v0.StatefulWorkload",   // Level 2 (for cache)
		"elements.opm.dev/core/v0.ConfigMap",          // Level 0
	]

	description: "Complete web application stack with frontend, backend, database, and cache (4-level nesting)"
	labels: {
		"core.opm.dev/category":      "composite"
		"core.opm.dev/nesting-level": "4"
	}
}

// Note: WebApplicationStack helper is complex because it needs multiple StatelessWorkload instances
// In a real implementation, this would require more sophisticated composition patterns

/////////////////////////////////////////////////////////////////
//// DataPlatform - Level 4 composite (data-focused)
/////////////////////////////////////////////////////////////////

#DataPlatformSpec: {
	platformName: string

	// Primary database (uses SimpleDatabase - Level 3)
	primaryDB: {
		engine:   "postgres" | *"postgres"
		version:  string | *"15"
		size:     string | *"500Gi"
		dbName:   string
		username: string
		password: string
	}

	// Analytics database (uses SimpleDatabase - Level 3)
	analyticsDB: {
		engine:   "postgres" | *"postgres"
		version:  string | *"15"
		size:     string | *"1Ti"
		dbName:   string
		username: string
		password: string
	}

	// Caching layer (uses StatefulWorkload - Level 2)
	cache: {
		enabled:  bool | *true
		replicas: int | *3
		size:     string | *"50Gi"
	}

	// Message queue (uses StatefulWorkload - Level 2)
	messageQueue: {
		enabled:  bool | *true
		replicas: int | *3
		size:     string | *"100Gi"
	}

	config: [string]: string
	secrets: [string]: string
}

#DataPlatformElement: opm.#Composite & {
	name:        "DataPlatform"
	#apiVersion: "elements.opm.dev/core/v0"
	target: ["component"]
	schema: #DataPlatformSpec

	// Composes multiple Level 3 and Level 2 elements
	composes: [
		"elements.opm.dev/core/v0.SimpleDatabase",   // Level 3 (used multiple times)
		"elements.opm.dev/core/v0.StatefulWorkload", // Level 2
		"elements.opm.dev/core/v0.ConfigMap",        // Level 0
		"elements.opm.dev/core/v0.Secret",           // Level 0
	]

	description: "Complete data platform with multiple databases, cache, and message queue (4-level nesting)"
	labels: {
		"core.opm.dev/category":      "data"
		"core.opm.dev/nesting-level": "4"
	}
}

// Simplified DataPlatform helper for single-component usage
#DataPlatform: opm.#Component & {
	#elements: (#DataPlatformElement.#fullyQualifiedName): #DataPlatformElement

	dataPlatform: #DataPlatformSpec

	// Note: Full implementation would require multi-component support
	// This demonstrates the schema and composition pattern
}
