# Platform Provider Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the schema and structure for Platform Providers and Transformers. A **Provider** acts as an adapter layer that translates abstract OPM components into concrete platform resources (e.g., Kubernetes manifests, Terraform resources).

It achieves this through a registry of **Transformers**, which are individual translation units responsible for specific component types.

### Core Principle: The Translation Layer

The Provider separates the *intent* (Component) from the *implementation* (Platform Resources).
- **Component**: "I need a stateless container with 3 replicas."
- **Provider**: "I will turn that into a Kubernetes Deployment and Service."

## Schema

### Provider

The `#Provider` definition serves as the root of a platform adapter.

```cue
#Provider: {
    apiVersion: "core.opm.dev/v0"
    kind:       "Provider"
    
    metadata: {
        name:        string
        description: string
        version:     string
        minVersion:  string // Minimum supported OPM version
    }

    // Transformer Registry
    // Maps unique keys to Transformer definitions
    transformers: [string]: #Transformer

    // Computed lists of all OPM definitions supported by this provider
    // (Automatically derived from the transformers map)
    #declaredResources: [...] 
    #declaredTraits:    [...]
    #declaredPolicies:  [...]
}
```

### Transformer

The `#Transformer` definition declares how to match and convert a component.

```cue
#Transformer: {
    metadata: {
        name:        string
        description: string
    }

    // Matching Criteria (See transformer-matching.md)
    requiredLabels?:    [string]: string
    requiredResources:  [string]: #Resource
    requiredTraits:     [string]: #Trait
    requiredPolicies:   [string]: #Policy
    
    optionalResources: [string]: #Resource
    optionalTraits:    [string]: #Trait
    optionalPolicies:  [string]: #Policy

    // The Transform Function
    #transform: {
        #component: #Component // Input
        #context:   {...}      // Context (module name, etc.)

        // Output MUST be a list of resources
        output: [...] 
    }
}
```

## The Transform Function

The `#transform` field is a CUE function (struct with inputs and outputs).

- **Input**: `#component` (The fully unified component being transformed).
- **Output**: `output` (A list of platform-specific resources).

**Constraint**: The `output` field MUST be a list, even if generating a single resource. This ensures consistent handling when concatenating outputs from multiple transformers.

## Registry & Discovery

The Provider automatically computes the set of supported OPM definitions by inspecting its registered transformers. This allows the CLI to answer questions like "Which traits does this provider support?".

```cue
// Pseudo-code for computation logic in #Provider
#declaredTraits: flatten([
    for t in transformers {
        keys(t.requiredTraits) + keys(t.optionalTraits)
    }
])
```

## Examples

### Kubernetes Provider Definition

```cue
package k8s

import "opm.dev/core@v0"

#KubernetesProvider: core.#Provider & {
    metadata: {
        name:        "kubernetes"
        description: "Standard Kubernetes Provider"
        version:     "1.0.0"
        minVersion:  "0.1.0"
    }

    transformers: {
        "deployment": #DeploymentTransformer
        "service":    #ServiceTransformer
    }
}
```

### Deployment Transformer

```cue
#DeploymentTransformer: core.#Transformer & {
    metadata: {
        name:        "DeploymentTransformer"
        description: "Generates a K8s Deployment for stateless workloads"
    }

    // Matches components with Container resource and "stateless" label
    requiredLabels: {
        "core.opm.dev/workload-type": "stateless"
    }
    requiredResources: {
        "opm.dev/resources/workload@v0#Container": _
    }

    #transform: {
        #component: _
        #context:   _

        output: [{
            apiVersion: "apps/v1"
            kind:       "Deployment"
            metadata: {
                name: #component.metadata.name
                // ...
            }
            spec: {
                replicas: #component.spec.replicas
                // ...
            }
        }]
    }
}
```

## Functional Requirements

### Provider Structure

- **FR-13-001**: `#Provider` MUST contain a `transformers` map registry.
- **FR-13-002**: Provider MUST compute `#declaredResources`, `#declaredTraits`, and `#declaredPolicies` by aggregating requirements from all registered transformers.
- **FR-13-003**: `#Transformer` MUST declare matching criteria (`requiredLabels`, `requiredResources`, etc.) and a `#transform` function.
- **FR-13-004**: The `#transform.output` field MUST be a list of resources.
- **FR-13-005**: `#Renderer` (if defined) converts the transformed resource list into final manifest formats (yaml/json). *Note: Detailed renderer spec is out of scope for this document, but the Provider feeds into it.*

## Acceptance Criteria

1. **Given** a Provider with 2 transformers, **When** evaluated, **Then** `#declaredTraits` contains the union of traits from both.
2. **Given** a Transformer, **When** `#transform` produces a single object instead of a list, **Then** validation fails (schema enforces list type `[...]`).
3. **Given** a Provider, **When** validated, **Then** it must have metadata including name and version.

## Matching Logic

For details on how the system selects which transformer to use for a given component, see the [Transformer Matching Subspec](./transformer-matching.md).
