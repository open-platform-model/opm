package security

import (
	core "opm.dev/core@v1"
)

/////////////////////////////////////////////////////////////////
//// Encryption Policy Definition
/////////////////////////////////////////////////////////////////

#EncryptionPolicy: close(core.#PolicyDefinition & {
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

#EncryptionScope: close(core.#ScopeDefinition & {
	#policies: {(#EncryptionPolicy.metadata.fqn): #EncryptionPolicy & {metadata: target: "scope"}}
})

#EncryptionComponent: close(core.#ComponentDefinition & {
	#policies: {(#EncryptionPolicy.metadata.fqn): #EncryptionPolicy & {metadata: target: "component"}}
})
