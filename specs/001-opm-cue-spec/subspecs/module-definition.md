# Module Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)
**Status**: Draft
**Last Updated**: 2026-01-21

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

    // Optional Scopes and Policies
    #scopes?: [Id=string]: #Scope
    #policies?: [Id=string]: #Policy

    // The configuration schema (constraints)
    #spec: _

    // Default configuration values
    values: #Values
    
    // Status block for compile-time info and runtime probes
    #status?: #ModuleStatus
})
```

### #ModuleCompiled

This is an intermediate representation, not typically authored by users.

```cue
#CompiledModule: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "CompiledModule"
    metadata: #Module.metadata

    // Components are now flattened (blueprints expanded)
    #components: [string]: #Component

    // Optional Scopes and Policies
    #scopes?: [Id=string]: #Scope
    #policies?: [Id=string]: #Policy

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

- **FR-5-001**: `#Module` is the portable application blueprint containing `#components`, `#spec` (schema), `values` (defaults), optional `#scopes`, and optional `#policies`.
- **FR-5-002**: Module `#policies` are for runtime enforcement that CUE cannot validate at evaluation time.
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
