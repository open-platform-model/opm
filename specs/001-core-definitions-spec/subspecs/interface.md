# Interface Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)
**Status**: Draft
**Last Updated**: 2026-01-26

> **Feature Availability**: This definition is specified but currently **deferred** in CLI v1 to reduce initial complexity. It will be enabled in a future release.

## Overview

This document specifies the interface and dependency management system for the Open Platform Model (OPM). Interfaces declare what a module exposes to the outside world (`provides`) and what it requires from other modules or external systems (`consumes`). This enables dependency validation, impact analysis, and service discovery.

OPM supports two patterns for declaring interfaces:

| Pattern | Field | Complexity | Use Case |
|---|---|---|---|
| **Interface Pattern** | `#interfaces` | Structured | Well-defined contracts, automatic platform matching |
| **Standard Pattern** | `#provides`/`#consumes` | Explicit | Direct control, Kubernetes-native compatibility |

These patterns are **mutually exclusive** - a module must use one or the other.

## Core Concepts

### `#Interface`: The Reusable Contract

An `#Interface` is a reusable contract type that defines how modules can exchange capabilities. It has two sides:

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
#Interface: {
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
- **FR-101**: `#Interface` MUST have `#providerSpec` defining what a provider exposes.
- **FR-102**: `#Interface` MUST have `#consumerSpec` defining what a consumer requests.
- **FR-103**: OPM provides well-known interfaces: `Storage`, `Network`, `Database`, `Queue`.
- **FR-104**: Module `#interfaces.provides` declares interfaces using `#Interface` FQN types.
- **FR-105**: Module `#interfaces.consumes` declares dependencies using `#Interface` FQN types.
- **FR-106**: Platform automatically matches consumers to compatible providers by interface type.
- **FR-107**: Platform implements its own decision logic for selecting among multiple compatible providers.
- **FR-108**: `#InterfaceConsumes.required: false` indicates optional dependency.
- **FR-109**: Module with `#interfaces` MUST NOT have `#provides` or `#consumes` fields.
- **FR-110**: Custom `#Interface` types MAY be created.

## User Scenarios & Testing

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE.
-->

### User Story 1 - Define Reusable Interface Contract (Priority: P1)

As a **Module Author**, I want to define an `#Interface` with specific `#providerSpec` and `#consumerSpec` schemas, so that I can create a strong contract for capabilities (like "PostgresDB") that ensures providers and consumers are compatible.

**Why this priority**: This is the foundation of the interface system. Without defining the contract, modules cannot reliably exchange capabilities.

**Independent Test**: Create a CUE file with an `#Interface` definition. Verify it passes `cue vet` against the `#Interface` meta-schema.

**Acceptance Scenarios**:

1. **Given** a valid `#Interface` definition including `#providerSpec` and `#consumerSpec`, **When** evaluated against the meta-schema, **Then** it is marked as valid.
2. **Given** an `#Interface` definition missing `#providerSpec` or `#consumerSpec`, **When** evaluated, **Then** validation fails.

---

### User Story 2 - Declare Provided Interface (Interface Pattern) (Priority: P1)

As a **Module Author**, I want to use the `#interfaces.provides` block to implement a well-known interface, so that my module is automatically discoverable by any consumer requiring that specific interface type.

**Why this priority**: Core functionality for enabling service discovery and capability sharing.

**Independent Test**: Create a `#Module` with `#interfaces.provides` referencing a mock `#Interface`. Run validation.

**Acceptance Scenarios**:

1. **Given** a Module providing a 'Storage' interface, **When** evaluated, **Then** the provided `spec` must match the Storage `#providerSpec`.
2. **Given** a Module providing an interface with invalid fields, **When** evaluated, **Then** validation errors are reported.

---

### User Story 3 - Declare Consumed Interface (Interface Pattern) (Priority: P1)

As a **Module Author**, I want to use the `#interfaces.consumes` block to request a capability, so that the platform can automatically find a compatible provider and inject the necessary connection details.

**Why this priority**: Essential for declaring dependencies and enabling platform automation.

**Independent Test**: Create a `#Module` with `#interfaces.consumes` referencing a mock `#Interface`.

**Acceptance Scenarios**:

1. **Given** a Module consuming a 'Database' interface, **When** evaluated, **Then** the requirement `spec` must match the Database `#consumerSpec`.

---

### User Story 4 - Enforce Pattern Exclusivity (Priority: P1)

As a **Platform Operator**, I want the system to validate that a module uses *either* the Interface Pattern *or* the Standard Pattern (but not both), so that module definitions remain consistent and ambiguous configurations are prevented.

**Why this priority**: Critical for maintaining system integrity and preventing conflicting definitions.

**Independent Test**: Create a module that attempts to define both `#interfaces` and `#provides`. Run `cue vet`.

**Acceptance Scenarios**:

1. **Given** a Module with both `#interfaces` and `#provides` blocks, **When** evaluated, **Then** validation fails due to the mutual exclusivity constraint.
2. **Given** a Module using only one of the patterns, **When** evaluated, **Then** validation succeeds.

---

### User Story 5 - Handle Optional Dependencies (Priority: P2)

As a **Module Author**, I want to set `required: false` on a consumed interface, so that my module can still deploy (perhaps in a degraded mode) even if a specific feature provider is unavailable.

**Why this priority**: Improves module resilience and flexibility.

**Independent Test**: Simulate a deployment plan where a requested provider is missing.

**Acceptance Scenarios**:

1. **Given** a Module with an optional dependency (`required: false`), **When** no provider is found, **Then** the deployment plan proceeds without error.
2. **Given** a Module with a required dependency (`required: true`), **When** no provider is found, **Then** the deployment plan halts with an error.

---

### User Story 6 - Use Explicit/Ad-hoc Interfaces (Standard Pattern) (Priority: P2)

As a **Module Author**, I want to use `#provides` and `#consumes` directly without formal `#Interface` definitions, so that I can quickly define simple or one-off dependencies that don't require reusable contracts.

**Why this priority**: Supports legacy migration and simple use cases where the overhead of formal interfaces isn't justified.

**Independent Test**: Create a module using the `#provides` block instead of `#interfaces`.

**Acceptance Scenarios**:

1. **Given** a Module using `#provides.http` without a formal `#Interface` type, **When** evaluated, **Then** it is accepted as valid under the Standard Pattern.
