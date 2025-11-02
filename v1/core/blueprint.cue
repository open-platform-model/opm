package core

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Blueprint Definition
/////////////////////////////////////////////////////////////////

// #BlueprintDefinition: Defines a reusable blueprint
// that composes units and traits into a higher-level abstraction.
// Blueprints enable standardized configurations for common use cases.
#BlueprintDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Blueprint"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/blueprints/core@v1"
		name!:       #NameType                          // Example: "StatelessWorkload"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/blueprints/core@v1#StatelessWorkload"

		// Human-readable description of the definition
		description?: string

		// Optional metadata labels for categorization and filtering
		// Labels are used by OPM for definition selection and matching
		// Example: {"core.opm.dev/workload-type": "stateless"}
		labels?: #LabelsAnnotationsType

		// Optional metadata annotations for definition behavior hints (not used for categorization)
		// Annotations provide additional metadata but are not used for selection
		annotations?: #LabelsAnnotationsType
	}

	// Units that compose this blueprint (full references)
	composedUnits!: [...#UnitDefinition]

	// Traits that compose this blueprint (full references)
	composedTraits?: [...#TraitDefinition]

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	// Use # to allow inconcrete fields
	// TODO: Add OpenAPIv3 schema validation
	#spec!: (strings.ToCamel(metadata.name)): _
})

#BlueprintMap: [string]: #BlueprintDefinition
