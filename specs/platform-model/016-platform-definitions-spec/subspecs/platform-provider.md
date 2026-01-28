# Platform Provider Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

> **Feature Availability**: This definition is **enabled** in CLI v1.

## Overview

This document defines the schema and structure for Platform Providers and Transformers. A **Provider** acts as an adapter layer that translates abstract OPM components into concrete platform resources (e.g., Kubernetes manifests, Terraform resources).

It achieves this through a registry of **Transformers**, which are individual translation units responsible for a combination of resources and traits.

### Core Principle: The Translation Layer

The Provider separates the *intent* (Component) from the *implementation* (Platform Resources).

- **Component**: "I need a stateless container with 3 replicas."
- **Provider**: "I will turn that into a Kubernetes Deployment and Service."

## User Scenarios & Testing

### User Story 1 - Create a Platform Provider (Priority: P1)

A platform engineer defines a new Provider to act as an adapter for a specific infrastructure target (e.g., "Corporate K8s" or "Legacy VM Cloud"). They register it with a unique name and version so that the platform can identify and load it.

**Why this priority**: This is the foundational entity required to bridge OPM components to any infrastructure. Without it, no translation can occur.

**Independent Test**: Create a valid `#Provider` CUE definition and verify that the OPM system can load it and read its metadata.

**Acceptance Scenarios**:

1. **Given** a valid `#Provider` definition with `apiVersion`, `kind`, and `metadata`, **When** evaluated by the system, **Then** it is recognized as a valid platform adapter.
2. **Given** a provider definition, **When** inspected, **Then** it exposes a `transformers` registry map.

---

### User Story 2 - Implement Resource Transformation (Priority: P1)

A platform engineer creates a Transformer to map a high-level OPM Component into concrete platform resources. This defines the core logic of how an abstract "Container" becomes a concrete "Deployment".

**Why this priority**: The transformer contains the actual logic for resource generation. It is the core functional unit of the provider.

**Independent Test**: Define a `#Transformer` and run its `#transform` function with a mock `#component` input, asserting the output contains the expected platform resources.

**Acceptance Scenarios**:

1. **Given** a `#Transformer` registered in a Provider, **When** the `#transform` function is executed with a valid `#component` input, **Then** it produces a list of platform resources (e.g., K8s manifests) in the `output` field.
2. **Given** a specific component spec (e.g., `replicas: 3`), **When** transformed, **Then** the output values correctly reflect the input (e.g., `spec.replicas: 3`).

---

### User Story 3 - Selective Matching via Labels (Priority: P2)

A platform engineer configures a Transformer to only apply to components with specific characteristics using label matching. This allows distinguishing between different workload types (e.g., stateless vs stateful) within the same provider.

**Why this priority**: Essential for supporting complex environments where different component types require different handling logic.

**Independent Test**: Create two components with different labels and verify that the transformer matches only the one with the required label.

**Acceptance Scenarios**:

1. **Given** a Transformer with `requiredLabels: {"type": "frontend"}`, **When** a component with label `type: "frontend"` is evaluated, **Then** the Transformer matches and executes.
2. **Given** the same Transformer, **When** a component with `type: "backend"` is evaluated, **Then** the Transformer is ignored.

---

### User Story 4 - Provider Capability Discovery (Priority: P3)

A platform operator queries the Provider to understand which OPM features it supports. The system automatically aggregates capabilities from registered transformers.

**Why this priority**: Improves the operator experience and tooling capabilities, allowing for validation of module compatibility with a provider.

**Independent Test**: Define a provider with a specific set of transformers and inspect the computed `#declaredTraits` and `#declaredResources` fields.

**Acceptance Scenarios**:

1. **Given** a Provider with a transformer requiring `opm.dev/traits/scaling@v0#Replicas`, **When** the Provider's `#declaredTraits` field is evaluated, **Then** the list includes the full FQN of the Replicas trait.
2. **Given** that the provider is loaded by the CLI, **When** a user asks for supported traits, **Then** the CLI displays this trait as "Supported".

### Edge Cases

- **Empty Output**: What happens if a transformer produces an empty list? (Should be valid, effectively a "no-op").
- **Multiple Matches**: How does the system handle when multiple transformers match the same component? (See Transformer Matching subspec).
- **Invalid Output Type**: What happens if the output is not a list? (Validation error).

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
        
        // Optional labels for provider categorization
        labels?: #LabelsAnnotationsType
    }

    // Transformer Registry
    // Maps unique keys to Transformer definitions
    transformers: [string]: #Transformer

    // Computed lists of all OPM definitions supported by this provider
    // (Automatically derived from the transformers map)
    #declaredResources: [...string]
    #declaredTraits:    [...string]
    #declaredDefinitions: [...string]  // Concat of resources + traits
    
    // Open struct - allows for provider-specific extensions
    ...
}
```

### Transformer

The `#Transformer` definition declares how to match and convert a component.

```cue
#Transformer: {
    apiVersion: "opm.dev/core/v0"
    kind:       "Transformer"
    
    metadata: {
        apiVersion!:  #NameType
        name!:        #NameType
        fqn:          #FQNType & "\(apiVersion)#\(name)"
        description!: string
        
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Matching Criteria (See transformer.md)
    requiredLabels?:    #LabelsAnnotationsType
    requiredResources:  [string]: _
    requiredTraits:     [string]: _
    
    optionalResources?: [string]: _
    optionalTraits?:    [string]: _

    // The Transform Function
    #transform: {
        #component: _  // Unconstrained input
        context:    #TransformerContext

        // Output MUST be a single resource
        output: {...} 
    }
}
```

## The Transform Function

The `#transform` field is a CUE function (struct with inputs and outputs).

- **Input**: `#component` (The fully unified component being transformed).
- **Output**: `output` (A single platform-specific resource).

**Constraint**: Each transformer MUST output exactly one resource. When multiple resources are needed for a component (e.g., Deployment + Service), multiple transformers match the same component and each produces its own resource. The render pipeline aggregates outputs from all matched transformers.

## Registry & Discovery

The Provider automatically computes the set of supported OPM definitions by inspecting its registered transformers. This allows the CLI to answer questions like "Which traits does this provider support?".

```cue
// Actual CUE implementation in #Provider
#declaredResources: list.FlattenN([
    for _, transformer in transformers {
        list.Concat([
            [for fqn, _ in transformer.requiredResources {fqn}],
            [for fqn, _ in transformer.optionalResources {fqn}],
        ])
    },
], 1)

#declaredTraits: list.FlattenN([
    for _, transformer in transformers {
        list.Concat([
            [for fqn, _ in transformer.requiredTraits {fqn}],
            [for fqn, _ in transformer.optionalTraits {fqn}],
        ])
    },
], 1)

#declaredDefinitions: list.Concat([#declaredResources, #declaredTraits])
```

## Matching Plan Computation

The `#MatchTransformers` function computes the matching plan for a render pipeline. This maps each transformer to its list of matched components and is used during Phase 3 (Component Matching) of the render pipeline.

```cue
#MatchTransformers: {
    provider: #Provider
    module:   #ModuleRelease

    out: {
        // Iterate over all transformers in the provider
        for tID, t in provider.transformers {
            // Find all components in the module that match this transformer
            let matches = [
                for _, c in module.components
                if (#Matches & {transformer: t, component: c}).result {
                    c
                },
            ]

            // Only include this transformer if it matched at least one component
            if len(matches) > 0 {
                (tID): {
                    transformer: t
                    components:  matches
                }
            }
        }
    }
}
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

        output: {
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
        }
    }
}
```

## Functional Requirements

### Provider Structure

- **FR-13-001**: `#Provider` MUST contain a `transformers` map registry.
- **FR-13-002**: Provider MUST compute `#declaredResources` and `#declaredTraits` by aggregating FQNs from all registered transformers (both required and optional).
- **FR-13-003**: Provider MUST compute `#declaredDefinitions` as the concatenation of `#declaredResources` and `#declaredTraits`.
- **FR-13-004**: `#Provider` MUST be an open struct (not closed) to allow provider-specific extensions.
- **FR-13-005**: `#Provider.apiVersion` MUST be `"core.opm.dev/v0"`.
- **FR-13-006**: `#Transformer` MUST have full metadata including `apiVersion`, `name`, `fqn`, and `description`.
- **FR-13-007**: `#Transformer` MUST declare matching criteria (`requiredLabels`, `requiredResources`, etc.) and a `#transform` function.
- **FR-13-008**: The `#transform.output` field MUST be a single resource (not a list). Multiple resources per component are achieved through multiple transformers matching.
- **FR-13-009**: The `#MatchTransformers` function MUST compute the matching plan mapping transformers to their matched components.

## Matching Logic

For details on how the system selects which transformer to use for a given component, see the [Transformer Matching Subspec](./transformer-matching.md).
