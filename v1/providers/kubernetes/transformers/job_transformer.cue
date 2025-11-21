package transformers

import (
	core "opm.dev/core@v1"
	workload_resources "opm.dev/resources/workload@v1"
	workload_traits "opm.dev/traits/workload@v1"
)

// JobTransformer converts task workload components to Kubernetes Jobs
#JobTransformer: core.#Transformer & {
	metadata: {
		apiVersion:  "opm.dev/providers/kubernetes/transformers@v1"
		name:        "JobTransformer"
		description: "Converts task workload components to Kubernetes Jobs"

		labels: {
			"core.opm.dev/workload-type": "task"
			"core.opm.dev/resource-type": "job"
			"core.opm.dev/priority":      "10"
		}
	}

	// Required resources - Container MUST be present
	requiredResources: {
		"opm.dev/resources/workload@v1#Container": workload_resources.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - JobConfig is mandatory for Job
	requiredTraits: {
		"opm.dev/traits/workload@v1#JobConfig": workload_traits.#JobConfigTrait
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

		// Extract required JobConfig trait (will be bottom if not present)
		_jobConfig: #component.spec.jobConfig

		// Apply defaults for optional RestartPolicy trait
		// For Jobs, default restart policy should be "OnFailure" or "Never", not "Always"
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
			kind:       "Job"
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
				completions:           *requiredTraits["opm.dev/traits/workload@v1#JobConfig"].#defaults.completions | int
				if _jobConfig.completions != _|_ {
					completions: _jobConfig.completions
				}

				parallelism:           *requiredTraits["opm.dev/traits/workload@v1#JobConfig"].#defaults.parallelism | int
				if _jobConfig.parallelism != _|_ {
					parallelism: _jobConfig.parallelism
				}

				backoffLimit:          *requiredTraits["opm.dev/traits/workload@v1#JobConfig"].#defaults.backoffLimit | int
				if _jobConfig.backoffLimit != _|_ {
					backoffLimit: _jobConfig.backoffLimit
				}

				activeDeadlineSeconds: *requiredTraits["opm.dev/traits/workload@v1#JobConfig"].#defaults.activeDeadlineSeconds | int
				if _jobConfig.activeDeadlineSeconds != _|_ {
					activeDeadlineSeconds: _jobConfig.activeDeadlineSeconds
				}

				ttlSecondsAfterFinished: *requiredTraits["opm.dev/traits/workload@v1#JobConfig"].#defaults.ttlSecondsAfterFinished | int
				if _jobConfig.ttlSecondsAfterFinished != _|_ {
					ttlSecondsAfterFinished: _jobConfig.ttlSecondsAfterFinished
				}

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
		}]
	}
}
