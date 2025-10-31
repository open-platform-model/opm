package v1

/////////////////////////////////////////////////////////////////
//// Scope Definition
/////////////////////////////////////////////////////////////////

// #ScopeDefinition: Defines cross-cutting concerns and shared contexts
// that span multiple components within a system.
// Scopes encapsulate policies and configurations that apply
// to a group of components, enabling consistent governance
// and operational behavior across those components.
#ScopeDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Scope"

	metadata: {
		name!: string

		description?: string

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Policies applied by this scope
	// Only policies with target "scope" can be applied here
	#policies: [PolicyFQN=string]: #PolicyDefinition & {
		metadata: {
			name: string | *PolicyFQN
			// Validation: target must be "scope"
			target: "scope"
		}
	}

	// Policy applicability
	// Which components this scope applies to
	appliesTo: {
		// Component label selectors
		componentLabels?: [string]: #LabelsAnnotationsType

		// Specific component names
		components?: [...#ComponentDefinition]

		// Apply to all if not specified
		all?: bool | *false
	}

	_allFields: {
		if #policies != _|_ {
			for _, policy in #policies {
				if policy.#spec != _|_ {
					for k, v in policy.#spec {
						(k): v
					}
				}
			}
		}
	}

	// Fields exposed by this scope
	// Automatically turned into a spec
	// Must be made concrete by the user
	spec: close(_allFields)
})

#ScopeMap: [string]: #ScopeDefinition
