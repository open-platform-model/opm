# Bundle Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the Bundle system for OPM. A **Bundle** is a higher-level aggregation that groups multiple related **Modules** into a single distributable and deployable unit.

Bundles are useful for:

- **Full Stack Distribution**: Packaging a frontend module, backend module, and database module together.
- **Solution Sets**: Grouping related infrastructure services (e.g., observability stack).
- **Versioning**: Releasing a consistent set of module versions together.

### Core Principle: Aggregation

A Bundle does not define new resources or traits directly. Instead, it imports and composes existing Modules.

## Schema

### Bundle Definition (`#Bundle`)

The `#Bundle` definition is the blueprint for the collection.

```cue
#Bundle: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "Bundle"

    metadata: {
        apiVersion!: #NameType
        name!:       #NameType
        fqn:         #FQNType & "\(apiVersion)#\(name)"
        description?: string
        labels?:      #LabelsAnnotationsType
    }

    // Registry of modules included in this bundle
    // Key is a local identifier, value is the #Module definition
    #modules!: [string]: #Module

    // Bundle-level configuration schema
    // Can be used to expose global configuration that applies to multiple modules
    #spec!: _

    // Bundle-level default values
    values: #Values
})
```

### Compiled Bundle (`#CompiledBundle`)

The compiled form where all included modules are fully evaluated and flattened (if applicable). This is the Intermediate Representation (IR) ready for deployment.

```cue
#CompiledBundle: close({
    // ... metadata ...
    
    // Modules are fully compiled
    #modules!: [string]: #CompiledModule
    
    // Concrete values
    values: #Values
})
```

### Bundle Release (`#BundleRelease`)

The deployment artifact that binds a `#CompiledBundle` (or `#Bundle`) to specific environment configuration.

```cue
#BundleRelease: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "BundleRelease"

    metadata: {
        name!: string
        // ...
    }

    // Reference to the bundle
    #bundle!: #Bundle | #CompiledBundle

    // Concrete values satisfying #bundle.#spec
    values!: close(#bundle.#spec)
})
```

## Examples

### Defining a Bundle

```cue
package mybundle

import (
    "opm.dev/core@v0"
    "example.com/frontend@v1"
    "example.com/backend@v1"
)

#WebAppStack: core.#Bundle & {
    metadata: {
        apiVersion: "example.com/bundles@v0"
        name:       "WebAppStack"
    }

    #modules: {
        frontend: frontend.#Module
        backend:  backend.#Module
    }

    #spec: {
        region: string
        env:    "prod" | "staging"
    }

    values: {
        region: "us-east-1"
        env:    "prod"
    }
}
```

## Functional Requirements

### Aggregation

- **FR-12-001**: `#Bundle` MUST provide a mechanism (`#modules`) to group multiple `#Module` definitions.
- **FR-12-002**: The bundle MUST be able to import modules from different repositories/packages.
- **FR-12-003**: `#CompiledBundle` represents the state where all child modules have been compiled to `#CompiledModule` (blueprints expanded, defaults applied).
- **FR-12-004**: `#BundleRelease` MUST bind a Bundle to concrete values, creating a deployable instance of the entire stack.

## Acceptance Criteria

1. **Given** a Bundle with 2 modules, **When** compiled, **Then** the result contains 2 compiled modules.
2. **Given** a BundleRelease, **When** validated, **Then** the provided `values` must match the Bundle's `#spec`.
3. **Given** a Bundle, **When** checked for metadata, **Then** it must have `apiVersion` and `name`.

## Edge Cases

| Case | Behavior |
|------|----------|
| Bundle contains no modules | Valid (empty bundle), though not useful |
| Bundle values conflict with module values | *Undefined in v0 core* - Implementation dependent (usually bundle values inject into modules) |
| Cyclic dependencies between modules | CUE evaluation error |
