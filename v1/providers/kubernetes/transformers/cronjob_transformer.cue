package transformers

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// CronJobTransformer converts scheduled task components to Kubernetes CronJobs
#CronJobTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opm.dev/providers/kubernetes/transformers@v1"
		name:        "CronJobTransformer"
		description: "Converts scheduled task components to Kubernetes CronJobs"

		labels: {
			"core.opm.dev/workload-type": "scheduled-task"
			"core.opm.dev/resource-type": "cronjob"
			"core.opm.dev/priority":      "10"
		}
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - CronJobConfig is mandatory for CronJob
	requiredTraits: {
		"opm.dev/traits/workload@v1#CronJobConfig": workload_traits.#CronJobConfigTrait
	}

	// Optional traits
	optionalTraits: {
		"opm.dev/traits/workload@v1#RestartPolicy":      workload_traits.#RestartPolicyTrait
		"opm.dev/traits/workload@v1#SidecarContainers":  workload_traits.#SidecarContainersTrait
		"opm.dev/traits/workload@v1#InitContainers":     workload_traits.#InitContainersTrait
	}

	// No required policies
	requiredPolicies: {}

	// No optional policies
	optionalPolicies: {}

	#transform: {
		#component: core.#ComponentDefinition
		#context:   core.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Extract required CronJobConfig trait (will be bottom if not present)
		_cronConfig: #component.spec.cronJobConfig

		// Apply defaults for optional RestartPolicy trait
		// For CronJobs, default restart policy should be "OnFailure" or "Never", not "Always"
		_restartPolicy: *"OnFailure" | string
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Extract optional sidecar and init containers with defaults
		_sidecarContainers: *optionalTraits["opm.dev/traits/workload@v1#SidecarContainers"].#defaults | [...]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		_initContainers: *optionalTraits["opm.dev/traits/workload@v1#InitContainers"].#defaults | [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		output: [{
			apiVersion: "batch/v1"
			kind:       "CronJob"
			metadata: {
				name:      #component.metadata.name
				namespace: #context.name | *"default"
				labels: {
					app:                      #component.metadata.name
					"app.kubernetes.io/name": #component.metadata.name
					if #component.metadata.labels != _|_ {
						for k, v in #component.metadata.labels {
							"\(k)": v
						}
					}
				}
				if #component.metadata.annotations != _|_ {
					annotations: #component.metadata.annotations
				}
			}
			spec: {
				schedule: _cronConfig.scheduleCron

				if _cronConfig.suspend != _|_ {
					suspend: _cronConfig.suspend
				}

				concurrencyPolicy:          *requiredTraits["opm.dev/traits/workload@v1#CronJobConfig"].#defaults.concurrencyPolicy | string
				if _cronConfig.concurrencyPolicy != _|_ {
					concurrencyPolicy: _cronConfig.concurrencyPolicy
				}

				successfulJobsHistoryLimit: *requiredTraits["opm.dev/traits/workload@v1#CronJobConfig"].#defaults.successfulJobsHistoryLimit | int
				if _cronConfig.successfulJobsHistoryLimit != _|_ {
					successfulJobsHistoryLimit: _cronConfig.successfulJobsHistoryLimit
				}

				failedJobsHistoryLimit: *requiredTraits["opm.dev/traits/workload@v1#CronJobConfig"].#defaults.failedJobsHistoryLimit | int
				if _cronConfig.failedJobsHistoryLimit != _|_ {
					failedJobsHistoryLimit: _cronConfig.failedJobsHistoryLimit
				}

				jobTemplate: {
					spec: {
						template: {
							metadata: labels: {
								app:                      #component.metadata.name
								"app.kubernetes.io/name": #component.metadata.name
							}
							spec: {
								containers: [_container] + _sidecarContainers

								if len(_initContainers) > 0 {
									initContainers: _initContainers
								}

								restartPolicy: _restartPolicy
							}
						}
					}
				}
			}
		}]
	}
}
