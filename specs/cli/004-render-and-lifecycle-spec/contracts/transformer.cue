package transformer

// #Transformer defines the contract for all OPM transformers.
#Transformer: {
	apiVersion: "opmodel.dev/core/v0"
	kind:       "Transformer"

	metadata: {
		apiVersion!: #NameType                          // Example: "opmodel.dev/transformers/kubernetes@v0"
		name!:       #NameType                          // Example: "DeploymentTransformer"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opmodel.dev/transformers/kubernetes@v0#DeploymentTransformer"

		description!: string // A brief description of what this transformer produces

		// Labels for categorizing this transformer (not used for matching)
		labels?: #LabelsAnnotationsType

		// Annotations for additional transformer metadata
		annotations?: #LabelsAnnotationsType
	}

	// Labels that a component MUST have to match this transformer.
	// Component labels are inherited from the union of labels from all attached
	// #resources, #traits, and #policies.
	//
	// Example: A DeploymentTransformer requires stateless workloads:
	//   requiredLabels: {"core.opmodel.dev/workload-type": "stateless"}
	//
	// The Container resource defines this label, so components with Container
	// will have it. Transformers requiring "stateful" won't match.
	requiredLabels?: #LabelsAnnotationsType

	// Labels optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalLabels?: #LabelsAnnotationsType

	// Resources required by this transformer - component MUST include these
	// Map key is the FQN, value is the Resource definition (provides access to #defaults)
	requiredResources: [string]: _

	// Resources optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalResources: [string]: _

	// Traits required by this transformer - component MUST include these
	// Map key is the FQN, value is the Trait definition (provides access to #defaults)
	requiredTraits: [string]: _

	// Traits optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalTraits: [string]: _

	// Transform function
	// IMPORTANT: output must be a single resource
	#transform: {
		#component: _ // Unconstrained; validated by matching, not by the transform signature
		context:   #TransformerContext

		output: {...} // Must be a single provider-specific resource
	}
}

// Map of transformers by fully qualified name
#TransformerMap: [string]: #Transformer

// Provider context passed to transformers
#TransformerContext: close({
	#moduleMetadata:    _ // Injected during rendering
	#componentMetadata: _ // Injected during rendering
	name:               string // Injected during rendering (release name)
	namespace:          string // Injected during rendering (target namespace)

	moduleLabels: {
		if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}
	}

	componentLabels: {
		"app.kubernetes.io/instance": "\(name)-\(namespace)"

		if #componentMetadata.labels != _|_ {#componentMetadata.labels}
	}

	controllerLabels: {
		"app.kubernetes.io/managed-by": "open-platform-model"
		"app.kubernetes.io/name":       #componentMetadata.name
		"app.kubernetes.io/version":    #moduleMetadata.version
	}

	labels: {[string]: string}
	labels: {
		for k, v in moduleLabels {
			(k): "\(v)"
		}
		for k, v in componentLabels {
			(k): "\(v)"
		}
		for k, v in controllerLabels {
			(k): "\(v)"
		}
		...
	}
})

// #Matches evaluates whether a transformer's requirements are satisfied by a component.
// Implements the ALL-match semantics from 004-render-and-lifecycle-spec Section 4:
//   1. ALL requiredLabels present on component with matching values
//   2. ALL requiredResources FQNs exist in component.#resources
//   3. ALL requiredTraits FQNs exist in component.#traits
//
// Usage:
//   let match = (#Matches & {transformer: t, component: c}).result
//   if match { ... }
#Matches: {
	transformer: #Transformer
	component:   #Component

	// 1. Check Required Labels
	// Logic: All labels in transformer.requiredLabels must exist in component.metadata.labels with same value
	_reqLabels: *transformer.requiredLabels | {}
	_missingLabels: [
		for k, v in _reqLabels
		if len([for lk, lv in component.metadata.labels if lk == k && (lv & v) != _|_ {true}]) == 0 {
			k
		},
	]

	// 2. Check Required Resources
	// Logic: All keys in transformer.requiredResources must exist in component.#resources
	_reqResources: *transformer.requiredResources | {}
	_missingResources: [
		for k, v in _reqResources
		if len([for rk, rv in component.#resources if rk == k && (rv & v) != _|_ {true}]) == 0 {
			k
		},
	]

	// 3. Check Required Traits
	// Logic: All keys in transformer.requiredTraits must exist in component.#traits
	_reqTraits: *transformer.requiredTraits | {}
	_missingTraits: [
		for k, v in _reqTraits
		if component.#traits == _|_ || len([for tk, tv in component.#traits if tk == k && (tv & v) != _|_ {true}]) == 0 {
			k
		},
	]

	// Result: true if no requirements are missing
	result: len(_missingLabels) == 0 && len(_missingResources) == 0 && len(_missingTraits) == 0
}
