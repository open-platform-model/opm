package core

/////////////////////////////////////////////////////////////////
//// Bundle Definition
/////////////////////////////////////////////////////////////////

// #BundleDefinition: Defines a collection of modules. Bundles enable grouping
// related modules for easier distribution and management.
// Bundles can contain multiple modules, each representing a set of
// definitions (units, traits, blueprints, policies, scopes).
#BundleDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Bundle"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/bundles/core@v1"
		name!:       #NameType                          // Example: "ExampleBundle"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/bundles/core@v1#ExampleBundle"

		// Human-readable description of the bundle
		description?: string

		// Optional metadata labels for categorization and filtering
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for bundle behavior hints
		annotations?: #LabelsAnnotationsType
	}

	// Modules included in this bundle (full references)
	#modulesDefinitions!: #ModuleDefinitionMap

	// MUST be an OpenAPIv3 compatible schema
	#values!: _
})

#BundleDefinitionMap: [string]: #BundleDefinition

#Bundle: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Bundle"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/bundles/core@v1"
		name!:       #NameType                          // Example: "ExampleBundle"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/bundles/core@v1#ExampleBundle"

		// Human-readable description of the bundle
		description?: string

		// Optional metadata labels for categorization and filtering
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for bundle behavior hints
		annotations?: #LabelsAnnotationsType
	}

	// Modules included in this bundle (full references)
	#modules!: #ModuleMap

	// MUST be an OpenAPIv3 compatible schema
	#values!: _
})

#BundleMap: [string]: #Bundle

// #BundleRelease: The concrete deployment instance
// Contains: Reference to Bundle, concrete values (closed)
// Users/deployment systems create this to deploy a specific version
#BundleRelease: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "BundleRelease"

	metadata: {
		name!:        string
		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Reference to the Bundle to deploy
	bundle!: #Bundle

	// Concrete values (everything closed/concrete)
	// Must satisfy the value schema from bundle.values
	values!: close(bundle.#values)

	if bundle.#status != _|_ {status: bundle.#status}
	status?: {
		// Deployment lifecycle phase
		phase: "pending" | "deployed" | "failed" | "unknown" | *"pending"

		// Human-readable status message
		message?: string
	}
})

#BundleReleaseMap: [string]: #BundleRelease
