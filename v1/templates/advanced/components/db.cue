package components

import (
	core "opm.dev/core@v1"
	workload_units "opm.dev/units/workload@v1"
	storage_units "opm.dev/units/storage@v1"
)

// Database Component Definition

_db: core.#ComponentDefinition & {
	metadata: name: "db"

	// Compose units and traits using helpers
	workload_units.#Container
	storage_units.#Volumes

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
