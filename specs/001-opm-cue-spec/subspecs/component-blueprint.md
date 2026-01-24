# Component Blueprint Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the schema and behavior of Blueprints. A **Blueprint** represents a reusable pattern that composes Resources and Traits into a higher-level abstraction. Blueprints act as "templates" for components, allowing developers to standardize architectural patterns (e.g., "StatelessWorkload", "DatabaseCluster") and hide complexity.

### Core Principle: Composition

Blueprints enable composition by bundling:

1. **Resources**: The fundamental deployable units (e.g., Container, Service).
2. **Traits**: The behavioral modifiers (e.g., Replicas, Ingress).

When a component uses a blueprint, it inherits all the resources and traits defined in that blueprint.

## Schema

```cue
#Blueprint: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "Blueprint"

    metadata: {
        apiVersion!:  #NameType                          // Example: "opm.dev/blueprints/core@v0"
        name!:        #NameType                          // Example: "StatelessWorkload"
        fqn:          #FQNType & "\(apiVersion)#\(name)" // Computed: "{apiVersion}#{name}"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Resources that compose this blueprint (full references)
    composedResources!: [...#Resource]

    // Traits that compose this blueprint (full references)
    composedTraits?: [...#Trait]

    // MUST be an OpenAPIv3 compatible schema
    // The field and schema exposed by this definition
    // Matches the camelCase name of the blueprint
    #spec!: (strings.ToCamel(metadata.name)): _
})
```

## Examples

### Defining a Blueprint

```cue
package workload

import (
    core "opm.dev/core@v0"
    resources "opm.dev/resources/workload@v0"
    traits "opm.dev/traits/scaling@v0"
)

#StatelessWorkloadBlueprint: core.#Blueprint & {
    metadata: {
        apiVersion:  "opm.dev/blueprints/core@v0"
        name:        "StatelessWorkload"
        description: "A stateless workload with replicas"
    }

    composedResources: [
        resources.#ContainerResource
    ]

    composedTraits: [
        traits.#ReplicasTrait
    ]

    #spec: statelessWorkload: {
        image!:   string
        replicas: int | *1
    }
}
```

### Using a Blueprint (in Component)

```cue
myComponent: core.#Component & {
    #blueprints: {
        (#StatelessWorkloadBlueprint.metadata.fqn): #StatelessWorkloadBlueprint
    }

    spec: {
        statelessWorkload: {
            image: "nginx:latest"
            replicas: 3
        }
    }
}
```

## Functional Requirements

### Blueprint Structure

- **FR-3-001**: `#Blueprint` defines reusable compositions with `composedResources` and `composedTraits`.
- **FR-3-002**: Blueprints bundle Resources + Traits into "golden path" patterns.
- **FR-3-003**: `#Blueprint` MUST define `composedResources` (list of `#Resource`), optional `composedTraits` (list of `#Trait`).
- **FR-3-004**: `#Blueprint` MUST define a `#spec` field that acts as the configuration interface for the blueprint.
- **FR-3-005**: The `#spec` field key MUST match the camelCase version of the blueprint name (e.g., name="StatelessWorkload" -> #spec.statelessWorkload).

### Composition Logic

- **FR-3-006**: Blueprints MUST effectively bundle all `composedResources` and `composedTraits` such that consumers (Components) receive them as if they were directly attached.

## Acceptance Criteria

1. **Given** a Blueprint with `composedResources`, **When** validated, **Then** it must contain at least one resource reference.
2. **Given** a Blueprint with `#spec`, **When** validated, **Then** the key matches `strings.ToCamel(metadata.name)`.
3. **Given** a Component using a Blueprint, **When** evaluated, **Then** the component's `spec` includes the blueprint's schema.

## Edge Cases

| Case | Behavior |
|------|----------|
| Missing `composedResources` | Validation error (implied by usage, though schema allows empty list, practice requires content) |
| Missing `#spec` | Validation error (required field) |
| `#spec` key mismatch | Validation error (CUE constraint) |
