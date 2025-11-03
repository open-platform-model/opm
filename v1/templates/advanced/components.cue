package advanced

import (
	components "template.opm.dev/components"
)

// Component Definitions
// =====================
// This file contains references to component definitions for the module.

#components: {
	// Example: Frontend web server (uncomment and customize)
	web: components._web & {
		container: {
			image: #values.web.image
			ports: http: {
				targetPort: #values.web.port
				protocol:   "TCP"
			}
			resources: {
				limits: {
					cpu:    #values.web.resources.cpu
					memory: #values.web.resources.memory
				}
			}
		}
		replicas: #values.web.replicas
	}

	// Example: Backend API server (uncomment and customize)
	api: components._api & {
		container: {
			image: #values.api.image
			ports: apiPort: {
				targetPort: #values.api.port
				protocol:   "TCP"
			}
			resources: {
				limits: {
					cpu:    #values.api.resources.cpu
					memory: #values.api.resources.memory
				}
			}
		}
		replicas: #values.api.replicas
	}

	// Example: Background worker (uncomment and customize)
	worker: components._worker & {
		container: {
			image: #values.worker.image
			resources: {
				limits: {
					cpu:    #values.worker.resources.cpu
					memory: #values.worker.resources.memory
				}
			}
		}
		replicas: #values.worker.replicas
	}

	// Example: Database (uncomment and customize)
	db: components._db & {
		container: {
			image: #values.db.image
			resources: {
				limits: {
					cpu:    #values.db.resources.cpu
					memory: #values.db.resources.memory
				}
			}
			volumeMounts: {
				mountPath: "/var/lib/postgresql/data"
				name:      "db-data"
			}
		}
		volumes: dbData: {
			persitentClaim: {
				size:         #values.db.volumeSize
				accessMode:   #values.db.persistentStorage.accessMode
				storageClass: if #values.db.storageClass != _|_ {#values.db.storageClass}
			}
		}
	}
}
