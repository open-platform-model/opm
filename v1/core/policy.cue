package v1

import (
	"strings"
)

/////////////////////////////////////////////////////////////////
//// Policy Definition
/////////////////////////////////////////////////////////////////

// #PolicyDefinition: Encodes governance rules, security requirements,
// compliance controls, and operational guardrails.
// Policies define what MUST be true, not suggestions.
#PolicyDefinition: close({
	apiVersion: "opm.dev/v1/core"
	kind:       "Policy"

	metadata: {
		apiVersion!: #NameType                          // Example: "opm.dev/policies/security@v1"
		name!:       #NameType                          // Example: "Encryption"
		fqn:         #FQNType & "\(apiVersion)#\(name)" // Example: "opm.dev/policies/security@v1#Encryption"

		description?: string

		// Where this policy can be applied
		// component: Policy applies only to components
		// scope: Policy applies only to scopes
		target!: "component" | "scope"

		labels?:      #LabelsAnnotationsType
		annotations?: #LabelsAnnotationsType
	}

	// Enforcement level
	// strict: Policy violations block deployment
	// advisory: Policy violations generate warnings but allow deployment
	enforcement?: "strict" | "advisory" | *"strict"

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	// Use # to allow inconcrete fields
	// TODO: Add OpenAPIv3 schema validation
	#spec!: (strings.ToCamel(metadata.name)): _
})

#PolicyMap: [string]: #PolicyDefinition
