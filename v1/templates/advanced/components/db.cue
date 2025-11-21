package components

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	storage_resources "opm.dev/resources/storage@v1"
)

// Database Component Definition

_db: core.#ComponentDefinition & {
	metadata: name: "db"

	// Compose resources and traits using helpers
	workload_resources.#Container
	storage_resources.#Volumes

	// Define concrete spec values
	spec: {
		container: {
			name:  "database"
			image: string
			ports: {
				db: {
					name:       "db"
					protocol:   "TCP"
					targetPort: 5432
				}
			}
			volumeMounts: {
				dbData: {
					name:      "dbData"
					mountPath: "/var/lib/postgresql/data"
				}
			}
		}
		volumes: {
			dbData: {
				name: "dbData"
				persistentClaim: {
					size:         string
					accessMode:   "ReadWriteOnce"
					storageClass: "standard"
				}
			}
		}
	}
}
