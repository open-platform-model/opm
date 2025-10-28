// Developer Flow Example: Supabase Application
// This demonstrates a complete Supabase stack based on the official docker-compose.yml
//
// Supabase is an open-source Firebase alternative with:
// - PostgreSQL database
// - Auto-generated REST APIs
// - Realtime subscriptions
// - Authentication
// - Storage
// - Edge Functions
package supabase

import (
	opm "github.com/open-platform-model/core"
)

//////////////////////////////////////////////////////////////////
// Developer creates Supabase ModuleDefinition
//////////////////////////////////////////////////////////////////

supabaseAppDefinition: opm.#ModuleDefinition & {
	#metadata: {
		name:        "supabase"
		version:     "1.0.0"
		description: "Complete Supabase stack with database, API gateway, auth, storage, and functions"
		labels: {
			"app.name": "supabase"
			team:       "platform"
		}
		annotations: {
			"owner": "platform-team@example.com"
		}
	}

	components: #components

	// Value schema - constraints only, no defaults
	// Developers define what can be configured
	values: {
		database: {
			password!:    string // Required - PostgreSQL password
			storageSize!: string // Required - e.g., "10Gi"
		}
		jwt: {
			secret!:     string // Required - JWT signing secret
			anonKey!:    string // Required - Anonymous key for public access
			serviceKey!: string // Required - Service role key for admin access
		}
		auth: {
			siteUrl!:   string // Required - Main site URL
			allowList!: string // Required - Comma-separated allowed redirect URLs
		}
		studio: {
			publicUrl!: string // Required - Public URL for Supabase API
		}
		environment!: string // Required - Environment name
	}
}

