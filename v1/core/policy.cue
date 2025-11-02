package core

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

	// Policy enforcement configuration
	// Note: CUE always validates the structure/schema of the policy spec itself.
	// This field controls WHERE and WHEN the policy is ENFORCED by the platform.
	enforcement!: {
		// When enforcement happens
		// deployment: Enforced when resources are deployed (admission controllers, pre-flight checks)
		// runtime: Enforced continuously while running (monitoring, auditing, ongoing validation)
		// both: Enforced at both deployment time and continuously at runtime
		mode!: "deployment" | "runtime" | "both"

		// What happens when policy is violated
		// block: Reject the operation (deployment fails, request denied)
		// warn: Log warning but allow operation to proceed
		// audit: Record violation for compliance review without blocking
		onViolation!: "block" | "warn" | "audit"

		// Optional: platform-specific enforcement configuration
		// This is where platforms specify HOW to enforce (Kyverno, OPA, admission webhooks, etc.)
		// The structure is intentionally flexible to support different enforcement mechanisms
		platform?: _
	}

	// MUST be an OpenAPIv3 compatible schema
	// The field and schema exposed by this definition
	// Use # to allow inconcrete fields
	// TODO: Add OpenAPIv3 schema validation
	#spec!: (strings.ToCamel(metadata.name)): _
})

#PolicyMap: [string]: #PolicyDefinition
