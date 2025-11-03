package advanced

// Value Schema: Configuration Constraints
// ========================================
// Complex value schema organized by component.
// Can be further split into separate files if needed:
// - values/frontend.cue
// - values/backend.cue
// - values/data.cue

#values: {
	// Example: Frontend web server values (uncomment and customize)
	web: {
		// Required
		image!: string

		// Optional with constraints
		replicas?: int & >=1 & <=20 | *3
		port?:     int & >0 & <65536 | *80

		// Resource limits
		resources?: {
			cpu?:    string | *"100m"
			memory?: string | *"128Mi"
		}
	}

	// Example: Backend API values (uncomment and customize)
	api: {
		// Required
		image!: string

		// Optional with constraints
		replicas?: int & >=1 & <=50 | *5
		port?:     int & >0 & <65536 | *8080

		// Resource limits
		resources?: {
			cpu?:    string | *"500m"
			memory?: string | *"512Mi"
		}

		// API-specific configuration
		rateLimit?: {
			enabled?:        bool | *true
			requestsPerMin?: int & >0 | *1000
		}
	}

	// Example: Background worker values (uncomment and customize)
	worker: {
		// Required
		image!: string

		// Optional with constraints
		replicas?: int & >=1 & <=10 | *2

		// Worker-specific configuration
		jobQueue?: {
			maxConcurrent?: int & >0 | *5
			timeout?:       string | *"5m"
		}

		// Resource limits
		resources?: {
			cpu?:    string | *"250m"
			memory?: string | *"256Mi"
		}
	}

	// Example: Database values (uncomment and customize)
	db: {
		// Required
		image!:      string
		volumeSize!: string

		// Optional
		storageClass?: string | *"standard"

		// Database-specific configuration
		backup?: {
			enabled?:   bool | *true
			schedule?:  string | *"0 2 * * *" // Daily at 2 AM
			retention?: int & >0 | *7         // Days
		}

		// Resource limits
		resources?: {
			cpu?:    string | *"1000m"
			memory?: string | *"2Gi"
		}
	}
}
