# Feature Specification: OPM Component Transformers

**Parent Spec**: [OPM Core CUE Specification](../spec.md)
**Status**: Draft
**Last Updated**: 2026-01-26

> **Feature Availability**: This definition is **enabled** in CLI v2.

## User Scenarios & Testing *(mandatory)*

This section outlines the key user journeys for OPM Transformers, ordered by priority. Each story is independently testable and delivers a distinct piece of value to a specific user persona.

### User Story 1 - Basic Workload Transformation (Priority: P1)

As a **Module Author**, I want to define a simple, stateless web application component and have it automatically transformed into a standard Kubernetes Deployment and Service, so that I can abstract away boilerplate infrastructure code.

**Why this priority**: This is the core value proposition of OPM. It enables developers to work with high-level abstractions (`Container`, `Expose`) without needing to be Kubernetes experts.

**Independent Test**: A user can define a component with a `#Container` and `#Expose` trait. When rendered, the output should contain a valid Kubernetes `Deployment` and `Service` resource. This delivers a runnable application.

**Acceptance Scenarios**:

1. **Given** a component with a `#Container` resource and a label `workload-type: stateless`, **When** the component is rendered, **Then** a `DeploymentTransformer` matches and produces a Kubernetes `Deployment`.
2. **Given** a component with an `#Expose` trait, **When** the component is rendered, **Then** a `ServiceTransformer` matches and produces a Kubernetes `Service`.
3. **Given** a component with both, **When** rendered, **Then** the output is an aggregated list containing both the `Deployment` and `Service`.

---

### User Story 2 - Enforcing Platform Standards (Priority: P2)

As a **Platform Operator**, I want to create a transformer that automatically adds a security sidecar to any workload tagged with `security-profile: pci-dss`, so that I can enforce compliance across all teams without manual intervention.

**Why this priority**: This empowers Platform Operators to enforce standards, security, and best practices automatically, which is critical for governance in a multi-team environment.

**Independent Test**: Create a transformer that matches on the `security-profile: pci-dss` label. When a component with this label is rendered, the output should include the standard workload (e.g., a Deployment) AND the injected sidecar configuration.

**Acceptance Scenarios**:

1. **Given** a `SidecarTransformer` that has `requiredLabels: {"security-profile": "pci-dss"}`, **When** a component with that label is rendered, **Then** the `SidecarTransformer` executes in parallel with the main workload transformer.
2. **Given** a component without that label, **When** rendered, **Then** the `SidecarTransformer` does NOT match.

---

### User Story 3 - Preventing Ambiguous Transformations (Priority: P3)

As a **Module Author**, if I accidentally define two different workload transformers that match the exact same set of labels and resources, I want the system to fail with a clear error message, so that I can avoid unpredictable or non-deterministic behavior.

**Why this priority**: Predictability is essential. The system must protect users from ambiguous states that could lead to incorrect deployments.

**Independent Test**: Define two transformers with identical `requiredLabels`, `requiredResources`, and `requiredTraits`. Define a component that matches these requirements. The rendering process MUST fail with an error identifying the conflicting transformers.

**Acceptance Scenarios**:

1. **Given** two transformers with identical requirements are available, **When** a component that matches them is rendered, **Then** the system MUST produce an error and list the conflicting transformers.
2. **Given** two transformers with slightly different `requiredLabels` (e.g., `tier: frontend` vs `tier: backend`), **When** a component matches only one, **Then** the system renders successfully using the correct transformer.

## Overview

This document defines the algorithm for matching OPM components to transformers during the rendering phase. Transformers convert OPM components into platform-specific resources (e.g., Kubernetes Deployments, Services).

### Core Principle: Label-Based Matching

Transformers declare `requiredLabels` that components must have to match. This provides:

- **Explicit matching** - No scoring or ambiguity
- **Extensibility** - New labels can differentiate future transformer types
- **Fail-safe** - Missing labels = no match (not ambiguous match)

### Component Label Inheritance

Component labels are the union of labels from all attached definitions:

```text
Component.metadata.labels =
    Component's own labels
    + labels from all #resources
    + labels from all #traits
```

If definitions have conflicting labels, CUE unification fails automatically.

## Matching Algorithm

A transformer matches a component when **ALL** of the following are true:

1. **requiredLabels** - Component has ALL labels with matching values
2. **requiredResources** - Component `#resources` contains ALL FQNs
3. **requiredTraits** - Component `#traits` contains ALL FQNs

Optional inputs (`optionalLabels`, `optionalResources`, `optionalTraits`) do NOT affect matching; they only declare what additional data the transformer is capable of handling if present.

```cue
function matches(transformer, component) -> bool:

    // Check labels
    for key, value in transformer.requiredLabels:
        if component.metadata.labels[key] != value:
            return false

    // Check resources
    for fqn in keys(transformer.requiredResources):
        if fqn not in component.#resources:
            return false

    // Check traits
    for fqn in keys(transformer.requiredTraits):
        if fqn not in component.#traits:
            return false

    return true
```

## Conflict Detection

### Identical Requirements = Error

When multiple transformers match with **identical requirements** (same `requiredLabels`, `requiredResources`, `requiredTraits`), the system MUST error. This prevents ambiguity about which transformer handles the primary workload.

```text
Error: Multiple exact transformer matches for component "api"
  Transformers with identical requirements:
    - DeploymentTransformerA
    - DeploymentTransformerB

  Resolution: Differentiate transformers with different requiredLabels or requirements
```

### Different Requirements = Complementary

Transformers with **different requirements** are complementary and execute in **parallel**. Their outputs are aggregated.

| Transformer           | requiredLabels                | requiredTraits | Result                           |
| --------------------- | ----------------------------- | -------------- | -------------------------------- |
| DeploymentTransformer | `workload-type: stateless`    | (none)         | Matches stateless containers     |
| ServiceTransformer    | (none)                        | `Expose`       | Matches any component with Expose |

A component with `Container(stateless) + Expose` matches both → outputs `Deployment + Service`.

## Transformer Interface

Transformers must adhere to the following interface, supporting optional inputs and single-resource output.

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

    // Matching Requirements
    requiredResources: [string]: _
    requiredTraits:    [string]: _
    requiredLabels?:   #LabelsAnnotationsType

    // Optional Inputs (do not affect matching)
    optionalResources?: [string]: _
    optionalTraits?:    [string]: _
    optionalLabels?:    #LabelsAnnotationsType

    // Transform Function
    #transform: {
        #component: _  // Unconstrained - validated by matching, not signature
        context:    #TransformerContext

        // Output must be a single resource
        output: {...}
    }
}

#TransformerContext: close({
    #moduleMetadata:    _  // Injected during rendering
    #componentMetadata: _  // Injected during rendering
    name:               string  // Release name
    namespace:          string  // Target namespace

    moduleLabels: {
        if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}
    }

    componentLabels: {
        "app.kubernetes.io/instance": "\(name)-\(namespace)"
        
        if #componentMetadata.labels != _|_ {#componentMetadata.labels}
    }

    controllerLabels: {
        "app.kubernetes.io/managed-by": "open-platform-model"
        "app.kubernetes.io/name":       #componentMetadata.name
        "app.kubernetes.io/version":    #moduleMetadata.version
    }

    labels: {[string]: string}
    labels: {
        for k, v in moduleLabels {
            (k): "\(v)"
        }
        for k, v in componentLabels {
            (k): "\(v)"
        }
        for k, v in controllerLabels {
            (k): "\(v)"
        }
        ...
    }
})
```

## Examples

### Workload Transformer (Exclusive via Labels)

```cue
#DeploymentTransformer: #Transformer & {
    requiredResources: {
        "opm.dev/resources/workload@v0#Container": #ContainerResource
    }
    requiredLabels: {
        "core.opm.dev/workload-type": "stateless"
    }

    #transform: {
        #component: _
        context: _
        output: {
            apiVersion: "apps/v1"
            kind: "Deployment"
            // ... implementation
        }
    }
}
```

### Complementary Transformer (Trait-based)

```cue
#ServiceTransformer: #Transformer & {
    requiredResources: {
        "opm.dev/resources/workload@v0#Container": #ContainerResource
    }
    requiredTraits: {
        "opm.dev/traits/network@v0#Expose": #ExposeTrait
    }
    // No requiredLabels - matches any component with Expose trait

    #transform: {
        #component: _
        context: _
        output: {
            apiVersion: "v1"
            kind: "Service"
            // ... implementation
        }
    }
}
```

## Functional Requirements

- **FR-14-001**: Transformer MAY specify `requiredLabels`, `requiredResources`, `requiredTraits` for matching.
- **FR-14-002**: Transformer MAY specify `optionalLabels`, `optionalResources`, `optionalTraits` which do not affect matching.
- **FR-14-003**: Matching requires ALL `required*` criteria to be met.
- **FR-14-004**: Component labels are the union of `metadata.labels` + definition labels.
- **FR-14-005**: Transformers with identical requirements matching the same component MUST cause an error.
- **FR-14-006**: Transformers with different requirements matching the same component execute in parallel.
- **FR-14-007**: `#transform` MUST output a single resource (`output: {...}`).
- **FR-14-008**: Outputs from all matched transformers MUST be aggregated into a list.
- **FR-14-009**: `#TransformerContext` MUST be injected with `#moduleMetadata`, `#componentMetadata`, `name`, `namespace`, and computed tracking `labels`.
- **FR-14-010**: `#TransformerContext.labels` MUST aggregate `moduleLabels`, `componentLabels`, and `controllerLabels` with Kubernetes-standard label keys.
- **FR-14-011**: `#Transformer` MUST have full metadata including `apiVersion`, `name`, `fqn`, and `description`.
- **FR-14-012**: `#transform.#component` is unconstrained (`_`) - validation occurs during matching, not at transform signature level.

## Edge Cases

| Case                               | Behavior                                       |
| ---------------------------------- | ---------------------------------------------- |
| Component without `workload-type` label | Workload transformers requiring that label do not match |
| Multiple exact transformer matches | Error with list of conflicting transformers    |
| Complementary transformers match   | Both execute, outputs concatenated             |
| Unhandled traits (normal mode)     | Warning logged                                 |
| Unhandled traits (`--strict` mode) | Error with list of unhandled traits            |
| No transformers match              | Error with component details and available transformers |
| Transformer outputs empty struct   | Valid, results in no generated resource        |

## Success Criteria

- **SC-007**: Provider correctly computes declared resources/traits from transformers (including optional ones).
- **SC-008**: Matching logic respects `required*` vs `optional*` semantics.
- **SC-009**: Multiple exact transformer matches produce an error.
- **SC-010**: Parallel execution of complementary transformers produces correct aggregated output.
