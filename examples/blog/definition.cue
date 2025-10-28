// Developer Flow Example: Blog Application
// This demonstrates how a developer creates and tests a ModuleDefinition locally
//
// Label & Annotation Hierarchy (all levels merge):
// 1. ModuleDefinition level - Developer defines app-wide metadata (app.name, team, owner)
// 2. Module level - Platform/end-user adds deployment context (environment, deployed.by, git.commit)
// 3. Component level - Component-specific metadata (component, tier, metrics.port, backup.enabled)
package blog

import (
	opm "github.com/open-platform-model/core"
	elements "github.com/open-platform-model/elements/core"
)

//////////////////////////////////////////////////////////////////
// Developer creates ModuleDefinition
//////////////////////////////////////////////////////////////////

blogAppDefinition: opm.#ModuleDefinition & {
	#metadata: {
		name:        "blog"
		version:     "1.0.0"
		description: "Simple blog application with frontend and database"
		labels: {
			"app.name": #metadata.name
			team:       "content"
		}
		annotations: {
			"owner": "content-team@example.com"
		}
	}

	components: {
		// Frontend component
		frontend: {
			#metadata: {
				name: "frontend"
				labels: {
					component: "frontend"
					tier:      "web"
				}
				annotations: {
					"metrics.port": "9090"
				}
			}

			// Use composite element
			elements.#StatelessWorkload

			statelessWorkload: {
				container: {
					name:  "blog-frontend"
					image: values.frontend.image
					ports: {
						http: {
							name:       "http"
							targetPort: 3000
							protocol:   "TCP"
						}
					}
					env: {
						DATABASE_URL: {
							name:  "DATABASE_URL"
							value: "postgresql://postgres:5432/blog"
						}
						NODE_ENV: {
							name:  "NODE_ENV"
							value: values.environment
						}
					}
				}
			}
		}

		// Database component
		database: {
			#metadata: {
				name: "database"
				labels: {
					component:      "database"
					tier:           "data"
					"storage.type": "postgresql"
				}
				annotations: {
					"backup.enabled": "true"
				}
			}

			// Use composite element for simple database
			elements.#SimpleDatabase

			simpleDatabase: {
				engine:   "postgres"
				version:  "15"
				dbName:   "blog"
				username: "admin"
				password: "changeme" // In production, use secrets
				persistence: {
					enabled: true
					size:    values.database.storageSize
				}
			}
		}
	}

	// Value schema - constraints only, no defaults
	values: {
		frontend: {
			image!: string // Required
		}
		database: {
			storageSize!: string // Required
		}
		environment!: string // Required
	}
}
