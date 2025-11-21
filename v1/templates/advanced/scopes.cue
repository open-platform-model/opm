package advanced

import (
	scopes "opm.dev/templates/advanced/scopes"
)

// Scope Definitions
// =================
// Scopes define relationships between components and apply policies.
// This is optional but useful for:
// - Defining network boundaries
// - Applying security policies
// - Grouping components by function or tier

#scopes: {
	// Example: Frontend scope for public-facing components (uncomment and customize)
	frontend: scopes._api

	// Example: Backend scope for internal services (uncomment and customize)
	backend: scopes._backend
}
