package core

/////////////////////////////////////////////////////////////////
//// Example Module Flow: ModuleDefinition → Module → ModuleRelease
/////////////////////////////////////////////////////////////////

// Developer creates ModuleDefinition
exampleModuleDefinition: #ModuleDefinition & {
	metadata: {
		apiVersion:  "opm.dev/modules/core@v1"
		name:        "MyApp"
		version:     "1.0.0"
		description: "Example multi-tier application"
	}

	#components: {
		web: #ComponentDefinition & {
			metadata: name: "web-server"

			// Use helper shortcuts
			#Container
			#Replicas
		}

		db: #ComponentDefinition & {
			metadata: name: "database"

			// Use helper shortcuts
			#Container
			#Volumes
		}
	}

	// Value schema: Constraints only, NO concrete values
	#values: {
		web: {
			image!:    string                // Required
			replicas?: int & >=1 & <=10 | *3 // Optional with default
		}
		db: {
			image!:      string // Required
			volumeSize!: string // Required
		}
	}
}

// User creates ModuleRelease with concrete values
// exampleRelease: #ModuleRelease & {
// 	metadata: {
// 		name:      "my-app-production"
// 		namespace: "production"
// 		labels: {
// 			"environment": "production"
// 			"team":        "platform"
// 		}
// 	}

// 	// Reference the Module
// 	#module: exampleModuleDefinition

// 	// Provide concrete values
// 	values: {
// 		web: {
// 			image:    "myregistry.io/my-app/web:v1.2.3"
// 			replicas: 5
// 		}
// 		db: {
// 			image:      "postgres:14"
// 			volumeSize: "100Gi"
// 		}
// 	}

// 	// Status would be populated by deployment system
// 	status: {
// 		phase:      "deployed"
// 		message:    "Successfully deployed"
// 		deployedAt: "2025-10-30T10:00:00Z"
// 	}
// }
