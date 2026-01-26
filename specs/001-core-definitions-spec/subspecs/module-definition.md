# Module Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)
**Status**: Draft
**Last Updated**: 2026-01-21

> **Feature Availability**: This definition is **enabled** in CLI v1.

## Overview

This document defines the core entities related to the OPM Module: `#Module`, `#ModuleCompiled`, and `#ModuleRelease`. These three definitions represent the lifecycle of a module from its source code definition to a concrete, deployable instance.

### Core Principle: The Module Lifecycle

1. **`#Module` (Define)**: The source of truth. This is the portable, versioned blueprint created by a developer. It contains components, a configuration schema (`#spec`), and default `values`.
2. **`#ModuleCompiled` (Compile)**: An intermediate representation. This is the result of resolving and expanding the `#Module`, primarily by flattening any `#Blueprints` into their constituent resources and traits. This is the state before user-specific values are applied.
3. **`#ModuleRelease` (Instantiate)**: A deployable instance. This binds a `#Module` (or `#ModuleCompiled`) to a specific set of user-provided `values` and targets a specific environment (like a Kubernetes namespace).

## Schema

### #Module

This is the primary authoring definition for an application or service.

```cue
#Module: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "Module"
    metadata: {
        apiVersion!: #NameType
        name!:       #NameType
        fqn:         #FQNType & "\(apiVersion)#\(name)"
        version!:    #VersionType
        // ... other metadata
    }

    // The components that make up the module
    #components: [Id=string]: #Component

    // Optional Scopes
    #scopes?: [Id=string]: #Scope

    // The configuration schema (constraints)
    #spec: _

    // Default configuration values
    values: #Values
    
    // Status block for compile-time info and runtime probes
    #status?: #ModuleStatus
})
```

## Module Values

This section defines the configuration values system for Modules. It separates schema constraints from data defaults and defines the override hierarchy.

### Core Principle: Schema vs Data

- **`#spec`**: The schema, defined in CUE. It sets types, constraints, and validation rules. No default values should be here.
- **`values`**: The data, defined in `values.cue` and mapped to `#Module.values`. It contains concrete defaults and must unify with `#spec`.

### Core Principle: Immutable Platform Overrides

Values flow through a hierarchy. Once a higher-authority layer (Platform Team) sets a value and makes it concrete, lower layers (End Users) cannot change it without a unification error.

### Value Hierarchy

1. **Module Author Defaults** (`values.cue` in module repo): baseline defaults provided by the module author.
2. **Platform Overrides** (Platform repository): platform team imports the module and unifies their own `values` object. They can use concrete values (e.g., `replicas: 3`) to lock configuration.
3. **User Overrides** (Deployment time): end-user provides values (e.g., `helm install -f values.yaml`). These unify with the result of 1+2.

### Examples

#### 1. Module Author Definition

```cue
// module.cue
#Module & {
    #spec: {
        replicas: int & >=1
        image: string
    }
    values: {
        replicas: 1 // Default
    }
}
```

#### 2. Platform Override (Locking)

```cue
// platform/prod/module.cue
import "upstream/module"

myProdModule: module.#Module & {
    values: {
        // Platform team enforces high availability
        // By making this concrete, users cannot override it without conflict
        replicas: 3
    }
}
```

#### 3. User Attempted Override

If a user tries to deploy `myProdModule` with `replicas: 1`:

- **Result**: CUE unification error (`3 != 1`). The platform constraint holds.

### Functional Requirements

- **FR-7-001**: `values` in Module MUST satisfy `#spec` and use OpenAPIv3-compatible data shapes.
- **FR-7-002**: `#spec` MUST be a pure data schema compatible with OpenAPIv3 generation (no `if/for` logic that depends on values).
- **FR-7-003**: `values.cue` file MUST contain concrete defaults satisfying the `#spec` schema.
- **FR-7-004**: Value override hierarchy: developer defaults → platform team overrides → end-user overrides.
- **FR-7-005**: Platform team overrides become immutable for end-users.
- **FR-7-006**: The system relies on CUE's unification properties to enforce immutability. If a value is made concrete by an upstream actor, downstream actors cannot change it.

### Acceptance Criteria

1. **Given** a Module with `#spec.port: int` and `values.port: 80`, **When** evaluated, **Then** it is valid.
2. **Given** a Module with `#spec.port: int` and missing `values`, **When** evaluated, **Then** it is incomplete (unless intended abstract).
3. **Given** a Platform override `replicas: 3`, **When** user supplies `replicas: 2`, **Then** evaluation fails.

### Edge Cases

| Case | Behavior |
|------|----------|
| Platform-locked value override attempt | CUE unification enforces immutability - evaluation fails |
| Module missing `values.cue` | Validation fails |
| `values` does not satisfy `#spec` | CUE validation error |
| Nested value override (partial struct) | CUE unifies at field level |

### Success Criteria

- **SC-005**: Modules without `values.cue` fail validation.
- **SC-006**: Platform-locked values cannot be overridden by end-users.

### #ModuleCompiled

This is an intermediate representation, not typically authored by users.

```cue
#CompiledModule: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "CompiledModule"
    metadata: #Module.metadata

    // Components are now flattened (blueprints expanded)
    #components: [string]: #Component

    // Optional Scopes
    #scopes?: [Id=string]: #Scope

    // The configuration schema (constraints)
    #spec: _

    // Default configuration values
    values: #Values
    
    // Status block for compile-time info and runtime probes
    #status?: #ModuleStatus
})
```

### #ModuleRelease

This is the final, concrete object that a deployment system would create.

```cue
#ModuleRelease: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "ModuleRelease"
    metadata: {
        name!:      string
        namespace!: string // Target environment
        // ...
    }

    // Reference to the module being deployed
    #module!: #CompiledModule | #Module

    // Concrete, user-provided values for this specific deployment
    values!: close(#module.#spec)
})
```

## Functional Requirements

- **FR-5-001**: `#Module` is the portable application blueprint containing `#components`, `#spec` (schema), `values` (defaults), and optional `#scopes`.
- **FR-5-003**: A distributable Module MUST be accompanied by a `values.cue` file with default values.
- **FR-5-004**: `#ModuleCompiled` is the compiled/optimized form with expanded Blueprints.
- **FR-5-005**: `#ModuleCompiled` is ready for value binding and deployment, representing a complete, self-contained definition.
- **FR-5-006**: `#ModuleRelease` binds a Module (or CompiledModule) to concrete `values` and a target namespace.
- **FR-5-007**: `#ModuleRelease.values` MUST be validated against the `#module.#spec` schema.

## Examples

### 1. Simple `#Module` Definition (`module.cue`)

```cue
package myapp

import "opm.dev/core@v0"

#Module: core.#Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "WebApp"
        version:    "1.0.0"
    }

    #components: {
        frontend: { /* ... Component definition ... */ }
    }

    #spec: {
        image: string
        replicas: int | *1
    }

    values: {
        image: "nginx:latest"
    }
}
```

### 2. Corresponding `#ModuleRelease`

```cue
package main

import (
    "opm.dev/core@v0"
    "example.com/modules@v0"
)

#Release: core.#ModuleRelease & {
    metadata: {
        name:      "my-webapp-in-prod"
        namespace: "production"
    }

    #module: myapp.#Module

    // User provides the final values
    values: {
        image:    "nginx:1.21.6"
        replicas: 5
    }
}
```
