package core

// Test Policy Definitions with different targets

// Component-level policy
#ResourceLimitPolicy: close(#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/workload@v1"
		name:        "ResourceLimit"
		description: "Enforces resource limits for component workloads"
		target:      #PolicyTarget.component // Component-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: resourceLimit: {
		cpu?: {
			request!: string & =~"^[0-9]+m$"
			limit!:   string & =~"^[0-9]+m$"
		}
		memory?: {
			request!: string & =~"^[0-9]+[MG]i$"
			limit!:   string & =~"^[0-9]+[MG]i$"
		}
	}
})

#ResourceLimit: close(#ComponentDefinition & {
	#policies: {(#ResourceLimitPolicy.metadata.fqn): #ResourceLimitPolicy}
})

// Scope-level policy
#NetworkProtocol: "TCP" | "UDP" | "ICMP" | *"TCP"
#NetworkPort:     uint & >0 & <65536
#Port: {
	name!:          string
	protocol:       #NetworkProtocol
	containerPort!: #NetworkPort
}

#NetworkRuleSchema: {
	ingress?: [...{
		from!: [...#ComponentDefinition]
		ports?: [...#Port]
	}]
	egress?: [...{
		to!: [...#ComponentDefinition]
		ports?: [...#Port]
	}]
	denyAll?: bool | *false
}
#NetworkRulesPolicy: close(#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/connectivity@v1"
		name:        "NetworkRules"
		description: "Defines network traffic rules"
		target:      #PolicyTarget.scope // Scope-only
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: networkRules: [ruleName=string]: #NetworkRuleSchema
})

#NetworkRules: close(#ScopeDefinition & {
	#policies: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
})

// Flexible policy (both)
#EncryptionPolicy: close(#PolicyDefinition & {
	metadata: {
		apiVersion:  "opm.dev/policies/security@v1"
		name:        "Encryption"
		description: "Enforces encryption requirements"
	}
	enforcement: {
		mode:        "deployment"
		onViolation: "block"
	}
	#spec: encryption: {
		atRest!:    bool | *true
		inTransit!: bool | *true
	}
})

#EncryptionScope: close(#ScopeDefinition & {
	#policies: {(#EncryptionPolicy.metadata.fqn): #EncryptionPolicy & {metadata: target: "scope"}}
})

#EncryptionComponent: close(#ComponentDefinition & {
	#policies: {(#EncryptionPolicy.metadata.fqn): #EncryptionPolicy & {metadata: target: "component"}}
})

//////////////////////////////////////////////////////////////////
//// Test Cases
//////////////////////////////////////////////////////////////////

// Valid: Component with component-level policy
_validComponentWithComponentPolicy: #ComponentDefinition & {
	metadata: name: "api"
	#units: {
		"opm.dev/units/workload@v1#Container": #ContainerUnit
	}
	#policies: {
		"opm.dev/policies/workload@v1#ResourceLimitPolicy": #ResourceLimitPolicy
	}
	#ResourceLimit
	spec: {}
}

// Valid: Component with flexible policy
_validComponentWithFlexiblePolicy: #ComponentDefinition & {
	metadata: name: "database"
	#units: {
		"opm.dev/units/workload@v1#Container": #ContainerUnit
	}
	#policies: {
		"opm.dev/policies/security@v1#EncryptionPolicy": #EncryptionPolicy
	}
	#EncryptionComponent
	spec: {}
}

// Valid: Scope with scope-level policy
_validScopeWithScopePolicy: #ScopeDefinition & {
	metadata: name: "production"
	#policies: {
		"opm.dev/policies/connectivity@v1#NetworkRulesPolicy": #NetworkRulesPolicy
	}
	#NetworkRules
}

// Valid: Scope with flexible policy
_validScopeWithFlexiblePolicy: #ScopeDefinition & {
	metadata: name: "secure-zone"
	#policies: {
		"opm.dev/policies/security@v1#EncryptionPolicy": #EncryptionPolicy
	}
	#EncryptionScope
}

// INVALID: Component with scope-only policy (will fail CUE validation)
// Uncomment to test validation failure:

// _invalidComponentWithScopePolicy: #ComponentDefinition & {
// 	metadata: name: "invalid"
// 	#units: {
// 		"opm.dev/units/workload@v1#Container": {
// 			apiVersion: "opm.dev/units/workload@v1"
// 			kind:       "Unit"
// 		}
// 	}
// 	#policies: {
// 		"opm.dev/policies/connectivity@v1#NetworkPolicy": #NetworkPolicy // ERROR: target is ["scope"], not allowed in component
// 	}
// 	spec: {}
// }

// INVALID: Scope with component-only policy (will fail CUE validation)
// Uncomment to test validation failure:

// _invalidScopeWithComponentPolicy: #ScopeDefinition & {
// 	metadata: name: "invalid-scope"
// 	policies: {
// 		"opm.dev/policies/workload@v1#ResourceLimitPolicy": #ResourceLimitPolicy // ERROR: target is ["component"], not allowed in scope
// 	}
// }
