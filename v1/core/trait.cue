package v1

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Trait Definition
/////////////////////////////////////////////////////////////////

// #TraitDefinition: Defines additional behavior or characteristics
// that can be attached to components.
#TraitDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Trait"

	metadata: {
		apiVersion!: #NameType                          // Example: "units.opm.dev/workload@v1"
		name!:       #NameType                          // Example: "Container"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "units.opm.dev/workload@v1#Container"

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

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	// Use # to allow inconcrete fields
	// TODO: Add OpenAPIv3 schema validation
	#spec!: (strings.ToCamel(metadata.name)): _

	// Units that this trait can be applied to (full references)
	appliesTo!: [...#UnitDefinition]
})

#TraitMap: [string]: #TraitDefinition
