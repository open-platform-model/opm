package core

/////////////////////////////////////////////////////////////////
//// Module Architecture - Three Layers
/////////////////////////////////////////////////////////////////

// #ModuleDefinition: The portable application blueprint created by developers and/or platform teams
// Developers: Create initial ModuleDefinitions with application intent
// Platform teams: Can inherit and extend upstream ModuleDefinitions via CUE unification
// Contains: Components, value schema (constraints only), optional module scopes
// Does NOT contain: Concrete values, flattened state
#ModuleDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleDefinition"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/modules/core@v1"
		name!:       #NameType                          // Example: "Blog"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/modules/core@v1#Blog"

		version!: #VersionType // Semantic version of this module definition

		defaultNamespace?: string | *"default"
		description?:      string
		labels?:           #LabelsAnnotationsType
		annotations?:      #LabelsAnnotationsType
	}

	// Components defined in this module
	#components: [Id=string]: #ComponentDefinition & {
		metadata: name: string | *Id
	}

	// Module-level scopes (developer-defined, optional)
	#scopes?: [Id=string]: #ScopeDefinition

	// Value schema - constraints only, NO defaults
	// Developers define the configuration contract
	// Platform teams can add defaults and refine constraints via CUE merging
	// MUST be OpenAPIv3 compliant (no CUE templating - for/if statements)
	#values: _

	#status?: {...}
})

#ModuleDefinitionMap: [string]: #ModuleDefinition

// #Module: The compiled and optimized form (IR - Intermediate Representation)
// Result of flattening a ModuleDefinition:
//   - Blueprints expanded into their constituent Units and Traits
//   - Structure optimized for runtime evaluation
//   - Ready for binding with concrete values
// May include platform additions (Policies, Scopes, Components) if created from
// a platform team's extended ModuleDefinition, but primary purpose is compilation
#Module: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Module"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/modules/core@v1"
		name!:       #NameType                          // Example: "ExampleModule"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/modules/core@v1#ExampleModule"

		version!: #VersionType // Semantic version of this module definition

		defaultNamespace?: string | *"default"
		description?:      string
		labels?:           #LabelsAnnotationsType
		annotations?:      #LabelsAnnotationsType
	}

	// Components (flattened by Go CLI)
	// Blueprints expanded into Units + Traits
	#components: [string]: #ComponentDefinition

	// Scopes (from ModuleDefinition, may include platform-added scopes)
	#scopes?: [Id=string]: #ScopeDefinition

	// Value schema (preserved from ModuleDefinition)
	#values: _

	#status?: {
		componentCount: len(#components)
		scopeCount?: {if #scopes != _|_ {len(#scopes)}}
		...
	}
})

#ModuleMap: [string]: #Module

// #ModuleRelease: The concrete deployment instance
// Contains: Reference to Module, concrete values (closed), target namespace
// Users/deployment systems create this to deploy a specific version
#ModuleRelease: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "ModuleRelease"

	metadata: {
		name!:        string
		namespace!:   string // Required for releases (target environment)
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Reference to the Module to deploy
	module!: #Module

	// Concrete values (everything closed/concrete)
	// Must satisfy the value schema from module.values
	values!: close(module.#values)

	if module.#status != _|_ {status: module.#status}
	status?: close({
		// Deployment lifecycle phase
		phase: "pending" | "deployed" | "failed" | "unknown" | *"pending"

		// Human-readable status message
		message?: string

		// Detailed status conditions (Kubernetes-style)
		conditions?: [...{
			type:                string // e.g., "Available", "Progressing", "Degraded"
			status:              "True" | "False" | "Unknown"
			reason?:             string
			message?:            string
			lastTransitionTime?: string // ISO 8601 timestamp
		}]

		// Deployment timestamp
		deployedAt?: string // ISO 8601 timestamp

		// Resources created by this release
		resources?: {
			count?: int
			kinds?: [...string]
		}
	})
})

#ModuleReleaseMap: [string]: #ModuleRelease
