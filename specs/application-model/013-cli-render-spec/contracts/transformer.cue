package transformer

// #Transformer defines the contract for all OPM transformers.
#Transformer: {
    // Metadata
    metadata: {
        name:        string
        description: string | *""
        version:     string | *"v1"
    }

    // Matching Criteria
    requiredLabels?:    { [string]: string }
    requiredResources?: { [string]: _ }
    requiredTraits?:    { [string]: _ }

    // Transformation Logic
    #transform: {
        #component: _ // Validated against core.#Component
        #context: {
            name:      string
            namespace: string
            version:   string
            provider:  string
            timestamp: string
            strict:    bool
            labels:    { [string]: string }
        }

        // Output must be a single Kubernetes-compatible resource
        output: {
            apiVersion: string
            kind:       string
            metadata: {
                name: string
                ...
            }
            ...
        }
    }
}
