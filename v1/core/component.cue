package core

/////////////////////////////////////////////////////////////////
//// Component Definition
/////////////////////////////////////////////////////////////////

// Workload type label key
#LabelWorkloadType: "core.opm.dev/workload-type"

#ComponentDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Component"

	metadata: {
		name!: string

		// Namespace (typically unified from Module)
		namespace?: string

		// Component labels - unified with resource/trait/blueprint labels
		// If definitions have conflicting labels, CUE unification will fail (automatic validation)
		labels?: #LabelsAnnotationsType
		// TODO: Enable label unification of the component from resources/traits/blueprints. Must be careful with conflicts.

		// Component annotations - unified with resource/trait/blueprint annotations
		// If definitions have conflicting annotations, CUE unification will fail (automatic validation)
		annotations?: #LabelsAnnotationsType
		// TODO: Enable annotation unification of the component from resources/traits/blueprints. Must be careful with conflicts.
	}

	// Resources applied for this component
	#resources: #ResourceMap

	// Traits applied to this component
	#traits?: #TraitMap

	// Blueprints applied to this component
	#blueprints?: #BlueprintMap

	// Policies applied to this component
	// Only policies with target "component" can be applied here
	#policies?: [PolicyFQN=string]: #PolicyDefinition & {
		metadata: {
			name: string | *PolicyFQN
			// Validation: target must be "component"
			target: "component"
		}
	}

	_allFields: {
		for _, resource in #resources {
			if resource.#spec != _|_ {
				for k, v in resource.#spec {
					(k): v
				}
			}
		}
		if #traits != _|_ {
			for _, trait in #traits {
				if trait.#spec != _|_ {
					for k, v in trait.#spec {
						(k): v
					}
				}
			}
		}
		if #blueprints != _|_ {
			for _, blueprint in #blueprints {
				if blueprint.#spec != _|_ {
					for k, v in blueprint.#spec {
						(k): v
					}
				}
			}
		}
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

	// Fields exposed by this component (merged from all resources, traits, and blueprints)
	// Automatically turned into a spec
	// Must be made concrete by the user
	// Have to do it this way because if we allowed the spec flattened in the root of the component
	// we would have to open the Definition which would prevent inconcrete components
	// Note: Uses close() with ... to allow validation in transformers while maintaining type safety
	spec: close({
		_allFields
		...
	})

	status: {
		resourceCount: len(#resources)
		traitCount?: {if #traits != _|_ {len(#traits)}}
		blueprintCount?: {if #blueprints != _|_ {len(#blueprints)}}
		policyCount?: {if #policies != _|_ {len(#policies)}}
	}
})

#ComponentMap: [string]: #ComponentDefinition
