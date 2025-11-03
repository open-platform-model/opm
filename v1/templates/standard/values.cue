package standard

// Value Schema: Constraints for Configuration
// ============================================
// This file defines the value schema separately from the module definition.
// This separation is useful for:
// - Complex value schemas
// - Reusing values across multiple modules
// - Team collaboration (different ownership)
// - Frequent value schema updates

// Value schema defines CONSTRAINTS, not concrete values
// Concrete values are provided at deployment time (ModuleRelease)
#values: {
	// Example: Web server configuration (uncomment and customize)
	web: {
		// Required field: container image
		image!: string

		// Optional field: number of replicas (default: 3)
		// Constraints: must be between 1 and 10
		replicas?: int & >=1 & <=10 | *3
	}

	// Example: Database configuration (uncomment and customize)
	db: {
		// Required field: container image
		image!: string

		// Required field: persistent volume size
		volumeSize!: string
	}
}
