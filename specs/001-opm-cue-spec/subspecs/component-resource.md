# Component Resource Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the schema and behavior of Resources. A **Resource** represents a fundamental, deployable entity that must exist in the runtime environment. Resources are the atoms of OPM composition - they answer the question "what is being deployed?"

Examples include `Container`, `Volume`, `ConfigMap`, `DatabaseInstance`.

### Core Principle: Fundamental Existence

Resources differ from Traits and Policies because they represent **existence**.

- A Component MUST have at least one Resource.
- Without a Resource, there is nothing to modify (Trait) or govern (Policy).

## Schema

```cue
#Resource: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "Resource"

    metadata: {
        apiVersion!:  #NameType                          // Example: "opm.dev/resources/workload@v0"
        name!:        #NameType                          // Example: "Container"
        fqn:          #FQNType & "\(apiVersion)#\(name)" // Computed
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // MUST be an OpenAPIv3 compatible schema
    // The field matches the camelCase name of the resource
    // Example: metadata.name="Container" -> #spec.container
    #spec!: (strings.ToCamel(metadata.name)): _
})
```

## Examples

### defining a Resource

```cue
package workload

import "opm.dev/core@v0"

#Container: core.#Resource & {
    metadata: {
        apiVersion: "opm.dev/resources/workload@v0"
        name:       "Container"
        labels: {
            "core.opm.dev/workload-type": "stateless"
        }
    }

    #spec: container: {
        image!: string
        ports?: [...{
            containerPort: int
            protocol:      *"TCP" | "UDP"
        }]
        env?: [string]: string
    }
}
```

### Using a Resource in a Component

```cue
myComponent: core.#Component & {
    #resources: {
        (#Container.metadata.fqn): #Container
    }

    spec: {
        container: {
            image: "nginx:latest"
            ports: [{containerPort: 80}]
        }
    }
}
```

## Functional Requirements

### Structure

- **FR-1-001**: `#Resource` **MUST** define an OpenAPIv3-compatible `#spec` schema.
- **FR-1-002**: The `#spec` field key **MUST** match the camelCase version of `metadata.name`.
- **FR-1-003**: A Resource MAY define default `metadata.labels` and `metadata.annotations`.
- **FR-1-004**: The `#Resource` definition **MUST** be a closed struct (`close({})`).

### Composition and Usage

- **FR-1-005**: A `#Resource` is the only definition type that satisfies the "existence" requirement of a Component.
- **FR-1-006**: The `#Component` schema **MUST** enforce the presence of at least one Resource in its `#resources` map.
- **FR-1-007**: The `#spec` field of a Resource defines a schema that **MUST** be unified into the `spec` of the Component to which it is applied.
- **FR-1-008**: A Component **MUST** inherit all `metadata.labels` and `metadata.annotations` from every Resource within its `#resources` map.

## Acceptance Criteria

1. **Given** a Resource with name "MyResource", **When** validated, **Then** `#spec` must have key "myResource".
2. **Given** a Resource with CUE constructs in `#spec` (like `if` or `for`), **When** evaluated, **Then** it must result in a concrete data schema (OpenAPIv3 compatible).
3. **Given** a Component with an empty `#resources` map, **When** evaluated, **Then** the CUE evaluation **MUST** fail.
4. **Given** a Resource with `metadata.labels: {"tier": "backend"}`, **When** applied to a component, **Then** the component's final `metadata.labels` MUST contain `{"tier": "backend"}`.
