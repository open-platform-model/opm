package examples

import (
	core "opm.dev/core@v1"
	workload_blueprints "opm.dev/blueprints/workload@v1"
)

/////////////////////////////////////////////////////////////////
//// DaemonWorkload Blueprint Example - Node Monitoring Agent
//// Demonstrates daemon workload (no replicas, runs on all nodes)
/////////////////////////////////////////////////////////////////

exampleDaemonWorkload: core.#ComponentDefinition & {
	metadata: {
		name: "node-exporter-daemon"
	}

	// Use the DaemonWorkload blueprint
	workload_blueprints.#DaemonWorkload

	spec: {
		daemonWorkload: {
			container: {
				name:  "node-exporter"
				image: "prom/node-exporter:v1.6.1"
				ports: {
					metrics: {
						name:       "metrics"
						targetPort: 9100
					}
				}
				resources: {
					requests: {
						cpu:    "100m"
						memory: "128Mi"
					}
					limits: {
						cpu:    "200m"
						memory: "256Mi"
					}
				}
				volumeMounts: {
					proc: {
						name:      "proc"
						mountPath: "/host/proc"
						readOnly:  true
					}
					sys: {
						name:      "sys"
						mountPath: "/host/sys"
						readOnly:  true
					}
				}
			}

			restartPolicy: "Always"

			updateStrategy: {
				type: "RollingUpdate"
				rollingUpdate: {
					maxUnavailable: 1
				}
			}

			healthCheck: {
				livenessProbe: {
					httpGet: {
						path: "/metrics"
						port: 9100
					}
					initialDelaySeconds: 15
					periodSeconds:       20
				}
				readinessProbe: {
					httpGet: {
						path: "/metrics"
						port: 9100
					}
					initialDelaySeconds: 5
					periodSeconds:       10
				}
			}
		}

		// Route blueprint spec to unit/trait specs
		container:      daemonWorkload.container
		restartPolicy:  daemonWorkload.restartPolicy
		updateStrategy: daemonWorkload.updateStrategy
		healthCheck:    daemonWorkload.healthCheck
	}
}
