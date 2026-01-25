# Feature Specification: OPM Interface Model (DRAFT)

**Status**: Draft (Archived)
**Last Updated**: 2026-01-21

## Overview

This document specifies the interface and dependency management system for the Open Platform Model (OPM). It was part of the original core specification but has since been separated for potential future development.

Interfaces declare what a module exposes to the outside world (`provides`) and what it requires from other modules or external systems (`consumes`). This enables dependency validation, impact analysis, and service discovery.

OPM supports two patterns for declaring interfaces:

| Pattern | Field | Complexity | Use Case |
|---|---|---|---|
| **Interface Pattern** | `#interfaces` | Structured | Well-defined contracts, automatic platform matching |
| **Standard Pattern** | `#provides`/`#consumes` | Explicit | Direct control, K8s-native compatibility |

These patterns are **mutually exclusive**—a module must use one or the other.

## Core Concepts

### `#InterfaceDefinition`: The Reusable Contract

An `#InterfaceDefinition` is a first-class, reusable contract type that defines how modules can exchange capabilities. It has two sides:

1. `#providerSpec`: What a provider of the interface exposes.
2. `#consumerSpec`: What a consumer of the interface requests.

This bidirectional schema enables the platform to validate compatibility and automatically match consumers to providers.

### Provides vs. Consumes

| Aspect | Provides | Consumes |
|---|---|---|
| **Direction** | Outward (what I offer) | Inward (what I need) |
| **Ownership** | This module exposes | Another module/system provides |
| **Validation** | Schema validation | Availability validation |

## Schema

### Interface Pattern Schema

```cue
// A reusable contract type
#InterfaceDefinition: {
    metadata!: {
        apiVersion!: #FQNType
        name!:       #NameType
        version!:    #VersionType
        description?: string
    }
    #providerSpec: _
    #consumerSpec: _
    fqn: "\(metadata.apiVersion)#\(metadata.name)"
}

// The `#interfaces` block within a #Module
#ModuleInterfaces: {
    provides?: { [name=string]: #InterfaceProvides }
    consumes?: { [name=string]: #InterfaceConsumes }
}

// An instance of a provided interface
#InterfaceProvides: {
    type!: #FQNType
    description?: string
    spec?: _ // Validated against #providerSpec
}

// An instance of a consumed interface
#InterfaceConsumes: {
    type!: #FQNType
    required?: bool | *true
    description?: string
    spec?: _ // Validated against #consumerSpec
}
```

### Standard Pattern Schema

```cue
// The `#provides` block within a #Module
#ModuleProvides: {
    [name=string]: #Interface
}

// The `#consumes` block within a #Module
#ModuleConsumes: {
    [name=string]: #InterfaceRequirement
}

// An inline interface definition
#Interface: {
    type!: "http" | "grpc" | "tcp" | "database" | "queue" | "custom"
    description?: string
    spec?: _
}

// An inline interface requirement
#InterfaceRequirement: {
    type!: "http" | "grpc" | "tcp" | "database" | "queue" | "custom"
    required?: bool | *true
    description?: string
    spec?: _
}
```

### Mutual Exclusivity in `#Module`

```cue
#Module: {
    // ...
    #interfaces?: #ModuleInterfaces
    #provides?:   #ModuleProvides
    #consumes?:   #ModuleConsumes

    // Constraint
    _patternCheck: {
        if #interfaces != _|_ {
            #provides: _|_
            #consumes: _|_
        }
    }
}
```

## Well-Known Interface Definitions

OPM provides a core set of well-known interfaces.

| Definition | Purpose | Provider Side | Consumer Side |
|---|---|---|---|
| `Storage` | Persistent storage | Capacity, performance, access modes | Size, access mode, storage class |
| `Network` | Network connectivity | Protocol, port, path | Protocol, port, timeout |
| `Database` | Database access | Engine, version, connection limits | Engine, min/max connections |
| `Queue` | Message queue | System, topics, format | System, topic, consumer group |

## Functional Requirements

- **FR-094**: Module MAY use interface pattern (`#interfaces`) OR standard pattern (`#provides`/`#consumes`).
- **FR-095**: Interface pattern and standard pattern are mutually exclusive on a single module.
- **FR-101**: `#InterfaceDefinition` MUST have `#providerSpec` defining what a provider exposes.
- **FR-102**: `#InterfaceDefinition` MUST have `#consumerSpec` defining what a consumer requests.
- **FR-103**: OPM provides well-known interfaces: `Storage`, `Network`, `Database`, `Queue`.
- **FR-104**: Module `#interfaces.provides` declares interfaces using `#InterfaceDefinition` FQN types.
- **FR-105**: Module `#interfaces.consumes` declares dependencies using `#InterfaceDefinition` FQN types.
- **FR-106**: Platform automatically matches consumers to compatible providers by interface type.
- **FR-107**: Platform implements its own decision logic for selecting among multiple compatible providers.
- **FR-108**: `#InterfaceConsumes.required: false` indicates optional dependency.
- **FR-109**: Module with `#interfaces` MUST NOT have `#provides` or `#consumes` fields.
- **FR-110**: Custom `#InterfaceDefinition` types MAY be created.

## User Scenarios

A developer declares what interfaces a module provides and consumes.

**Interface Pattern**: Uses `#interfaces` field with well-known `#InterfaceDefinition` types (`Storage`, `Network`, etc.). The platform automatically matches consumers to compatible providers.

**Standard Pattern**: Uses `#provides`/`#consumes` fields directly. The developer manually specifies all interface details. More compatible with existing K8s deployment patterns.

### Acceptance Scenarios

1. **Given** a Module using the interface pattern with `#interfaces.provides`, **When** evaluated, **Then** interfaces validate against `#InterfaceDefinition` schemas.
2. **Given** a Module using the interface pattern with `#interfaces.consumes`, **When** no compatible provider exists, **Then** deployment validation warns/fails based on the `required` field.
3. **Given** a Module with `#interfaces.consumes[x].required: false`, **When** a provider is unavailable, **Then** the module can deploy in a degraded mode.
4. **Given** a Module with both `#interfaces` and `#provides`/`#consumes`, **When** evaluated, **Then** validation fails due to mutual exclusivity.
