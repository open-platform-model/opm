package core

// Map of transformers by fully qualified name
#TransformerMap: [string]: #Transformer

// Transformer interface
// Transformers declare how to convert platform resources, traits, and policies
// into target format representations.
#Transformer: {
	apiVersion: "core.opm.dev/v1"
	kind:       "Transformer"
	metadata: {
		apiVersion!: #NameType                          // Example: "transformer.opm.dev/workload@v1"
		name!:       #NameType                          // Example: "DeploymentTransformer"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "transformer.opm.dev/workload@v1#DeploymentTransformer"

		description: string // A brief description of the transformer

		// Labels for categorizing transformers
		// Can be referenced in #transformersToComponents expressions for DRY matching
		// Example: transformer.#metadata.labels["core.opm.dev/workload-type"]
		// Common labels: {"core.opm.dev/workload-type": "stateless"}
		labels?: #LabelsAnnotationsType
	}

	// Resources required by this transformer - component MUST include these
	// Map key is the FQN, value is the full ResourceDefinition (provides access to #defaults)
	requiredResources: [string]: _

	// Resources optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalResources: [string]: _

	// Traits required by this transformer - component MUST include these
	// Map key is the FQN, value is the full TraitDefinition (provides access to #defaults)
	requiredTraits: [string]: _

	// Traits optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalTraits: [string]: _

	// Policies required by this transformer - component MUST include these
	// Map key is the FQN, value is the full PolicyDefinition (provides access to #defaults)
	requiredPolicies: [string]: _

	// Policies optionally used by this transformer - component MAY include these
	// If not provided, defaults from the definition can be used
	optionalPolicies: [string]: _

	// Transform function
	// IMPORTANT: output must be a list of resources, even if only one resource is generated
	// This allows for consistent handling and concatenation in the module orchestration layer
	#transform: {
		#component: #ComponentDefinition
		#context:   #TransformerContext

		output: [...] // Must be a list of provider-specific resources
	}
}

// Provider context passed to transformers
// Simplified: Components now have metadata unified from Module in CUE
#TransformerContext: close({
	// Module name and version
	name: string
})
