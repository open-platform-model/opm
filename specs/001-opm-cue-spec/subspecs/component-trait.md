# Component Trait Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the schema and behavior of Traits. A **Trait** represents a behavioral characteristic or configuration modifier that attaches to a Resource. Traits answer the question "how does this thing behave?"

Examples include `Replicas`, `HealthCheck`, `Expose`, `Sidecar`.

### Core Principle: Modification and Applicability

Traits modify resources. Therefore, they must declare **applicability** - which resources they are compatible with.

- A Trait cannot exist in isolation; it requires a Resource.
- A Trait declares its compatibility via `appliesTo`.

## Schema

```cue
#Trait: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "Trait"

    metadata: {
        apiVersion!:  #NameType
        name!:        #NameType
        fqn:          #FQNType & "\(apiVersion)#\(name)"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Resources that this trait can be applied to (full references)
    // Acts as a whitelist constraint
    appliesTo!: [...#Resource]

    // Configuration schema for this trait
    // Matches camelCase name
    #spec!: (strings.ToCamel(metadata.name)): _
})
```

## Examples

### Defining a Trait

```cue
package scaling

import (
    "opm.dev/core@v0"
    "opm.dev/resources/workload@v0"
)

#Replicas: core.#Trait & {
    metadata: {
        apiVersion: "opm.dev/traits/scaling@v0"
        name:       "Replicas"
    }

    // Only applies to container-based workloads
    appliesTo: [
        workload.#Container
    ]

    #spec: replicas: int | *1
}
```

### Applying a Trait

```cue
myComponent: core.#Component & {
    #resources: { ... }
    
    #traits: {
        (#Replicas.metadata.fqn): #Replicas
    }

    spec: {
        replicas: 3
    }
}
```

## Functional Requirements

### Structure

- **FR-2-001**: `#Trait` **MUST** define `appliesTo` as a list of compatible `#Resource` definitions.
- **FR-2-002**: The `#spec` field key **MUST** match the camelCase version of `metadata.name`.

### Applicability Logic

- **FR-2-003**: When a Trait is applied to a Component, the `#Component` schema **MUST** enforce that the Component's resources are compatible with the Trait's `appliesTo` declaration during CUE evaluation.
- **FR-2-004**: The validation is satisfied if at least one `#Resource` in the Component's `#resources` map is definitionally compatible with at least one of the `#Resource` definitions in the Trait's `appliesTo` list. If no resources match for any given Trait, the CUE evaluation **MUST** fail.

### Composition Behavior

- **FR-2-005**: The `#spec` field of a Trait defines a schema that **MUST** be unified into the `spec` of the Component to which it is applied.
- **FR-2-006**: A Component **MUST** inherit all `metadata.labels` and `metadata.annotations` from every Trait applied to it. In case of conflicting keys for concrete values, the CUE unification process **MUST** result in an error.
- **FR-2-007**: A Trait MAY define a `#defaults` field. The structure of `#defaults` **MUST** be compatible with the Trait's `#spec`. These defaults provide concrete values for the `spec` fields if they are not otherwise specified by the consuming Component.

## Acceptance Criteria

1. **Given** a Trait with `appliesTo: [#Container]`, **When** applied to a component with only `#Volume`, **Then** the CUE evaluation **MUST** fail with a validation error indicating incompatibility.
2. **Given** a Trait with `#spec`, **When** applied, **Then** the component `spec` includes the trait's configuration fields.
3. **Given** a Trait with `metadata.labels: {"tier": "backend"}`, **When** applied to a component, **Then** the component's final `metadata.labels` MUST contain `{"tier": "backend"}`.
4. **Given** a Trait with `#defaults: {replicas: 2}`, **When** applied to a component that does not specify `replicas`, **Then** the component's `spec.replicas` MUST evaluate to `2`.
