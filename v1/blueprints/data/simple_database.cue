package data

import (
	core "opm.dev/core@v1"
	schemas "opm.dev/schemas@v1"
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// SimpleDatabase Blueprint Definition
/////////////////////////////////////////////////////////////////

#SimpleDatabaseBlueprint: close(core.#BlueprintDefinition & {
	metadata: {
		apiVersion:  "opm.dev/blueprints/data@v1"
		name:        "SimpleDatabase"
		description: "A simple database workload with persistent storage"
		labels: {
			"core.opm.dev/category":      "data"
			"core.opm.dev/workload-type": "stateful"
		}
	}

	composedUnits: [
		workload_units.#ContainerUnit,
		storage_units.#VolumesUnit,
	]

	composedTraits: [
		workload_traits.#ReplicasTrait,
		workload_traits.#RestartPolicyTrait,
		workload_traits.#HealthCheckTrait,
	]

	#spec: simpleDatabase: schemas.#SimpleDatabaseSchema
})

#SimpleDatabase: close(core.#ComponentDefinition & {
	#blueprints: (#SimpleDatabaseBlueprint.metadata.fqn): #SimpleDatabaseBlueprint

	workload_units.#Container
	storage_units.#Volumes
	workload_traits.#Replicas
	workload_traits.#RestartPolicy
	workload_traits.#HealthCheck

	// Default/generated values - what WILL be generated
	spec: {
		simpleDatabase: schemas.#SimpleDatabaseSchema

		// Configure container based on database engine
		container: {
			name: "database"
			if simpleDatabase.engine == "postgres" {
				image: "postgres:\(simpleDatabase.version)"
			}
			if simpleDatabase.engine == "mysql" {
				image: "mysql:\(simpleDatabase.version)"
			}
			if simpleDatabase.engine == "mongodb" {
				image: "mongo:\(simpleDatabase.version)"
			}
			if simpleDatabase.engine == "redis" {
				image: "redis:\(simpleDatabase.version)"
			}
			env: {
				if simpleDatabase.engine == "postgres" {
					POSTGRES_DB: {
						name:  "POSTGRES_DB"
						value: simpleDatabase.dbName
					}
					POSTGRES_USER: {
						name:  "POSTGRES_USER"
						value: simpleDatabase.username
					}
					POSTGRES_PASSWORD: {
						name:  "POSTGRES_PASSWORD"
						value: simpleDatabase.password
					}
				}
				if simpleDatabase.engine == "mysql" {
					MYSQL_DATABASE: {
						name:  "MYSQL_DATABASE"
						value: simpleDatabase.dbName
					}
					MYSQL_USER: {
						name:  "MYSQL_USER"
						value: simpleDatabase.username
					}
					MYSQL_PASSWORD: {
						name:  "MYSQL_PASSWORD"
						value: simpleDatabase.password
					}
				}
				if simpleDatabase.engine == "mongodb" {
					MONGO_INITDB_DATABASE: {
						name:  "MONGO_INITDB_DATABASE"
						value: simpleDatabase.dbName
					}
					MONGO_INITDB_ROOT_USERNAME: {
						name:  "MONGO_INITDB_ROOT_USERNAME"
						value: simpleDatabase.username
					}
					MONGO_INITDB_ROOT_PASSWORD: {
						name:  "MONGO_INITDB_ROOT_PASSWORD"
						value: simpleDatabase.password
					}
				}
			}
			volumeMounts: {
				if simpleDatabase.persistence != _|_ && simpleDatabase.persistence.enabled {
					data: _dataVol & {
						if simpleDatabase.engine == "postgres" {
							mountPath: "/var/lib/postgresql/data"
						}
						if simpleDatabase.engine == "mysql" {
							mountPath: "/var/lib/mysql"
						}
						if simpleDatabase.engine == "mongodb" {
							mountPath: "/data/db"
						}
						if simpleDatabase.engine == "redis" {
							mountPath: "/data"
						}
					}
				}
			}
		}

		_dataVol: {
			name: "data"
			persistentClaim: {
				size:       simpleDatabase.persistence.size
				accessMode: "ReadWriteOnce"
				if simpleDatabase.persistence.storageClass != _|_ {
					storageClass: simpleDatabase.persistence.storageClass
				}
			}
		}

		// Configure volumes if persistence is enabled
		if simpleDatabase.persistence != _|_ && simpleDatabase.persistence.enabled {
			volumes: {
				data: _dataVol
			}
		}

		// Set replicas to 1 (databases typically run single instance)
		replicas: 1

		// Always restart
		restartPolicy: "Always"

		// Configure health checks based on engine
		healthCheck: {
			if simpleDatabase.engine == "postgres" {
				readinessProbe: {
					exec: {
						command: ["pg_isready", "-U", simpleDatabase.username]
					}
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
			if simpleDatabase.engine == "mysql" {
				readinessProbe: {
					exec: {
						command: ["mysqladmin", "ping", "-h", "localhost"]
					}
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
			if simpleDatabase.engine == "mongodb" {
				readinessProbe: {
					exec: {
						command: ["mongo", "--eval", "db.adminCommand('ping')"]
					}
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
			if simpleDatabase.engine == "redis" {
				readinessProbe: {
					exec: {
						command: ["redis-cli", "ping"]
					}
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
		}
	}
})
