# Transformer Matching Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2025-12-10

## Overview

This document defines the algorithm for matching OPM components to transformers during the rendering phase. Transformers convert OPM components into platform-specific resources (e.g., Kubernetes Deployments, Services).

### Core Principle: Label-Based Matching

Transformers declare `requiredLabels` that components must have to match. This provides:

- **Explicit matching** - No scoring or ambiguity
- **Extensibility** - New labels can differentiate future transformer types
- **Fail-safe** - Missing labels = no match (not ambiguous match)

### Component Label Inheritance

Component labels are the union of labels from all attached definitions:

```
Component.metadata.labels = 
    Component's own labels
    + labels from all #resources
    + labels from all #traits  
    + labels from all #policies
```

If definitions have conflicting labels, CUE unification fails automatically.

## Matching Algorithm

A transformer matches a component when **ALL** of the following are true:

1. **requiredLabels** - Component has ALL labels with matching values
2. **requiredResources** - Component `#resources` contains ALL FQNs
3. **requiredTraits** - Component `#traits` contains ALL FQNs
4. **requiredPolicies** - Component `#policies` contains ALL FQNs

```
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
    
    // Check policies
    for fqn in keys(transformer.requiredPolicies):
        if fqn not in component.#policies:
            return false
    
    return true
```

## Conflict Detection

### Identical Requirements = Error

When multiple transformers match with **identical requirements** (same requiredLabels, requiredResources, requiredTraits, requiredPolicies), the system MUST error:

```
Error: Multiple exact transformer matches for component "api"
  Transformers with identical requirements:
    - DeploymentTransformerA
    - DeploymentTransformerB
  
  Resolution: Differentiate transformers with different requiredLabels or requirements
```

### Different Requirements = Complementary

Transformers with **different requirements** are complementary and both execute:

| Transformer | requiredLabels | requiredTraits | Result |
|-------------|---------------|----------------|--------|
| DeploymentTransformer | `workload-type: stateless` | (none) | Matches stateless containers |
| ServiceTransformer | (none) | `Expose` | Matches any component with Expose |

A component with `Container(stateless) + Expose` matches both → outputs Deployment + Service.

## Examples

### Workload Transformers (Exclusive via Labels)

```cue
#DeploymentTransformer: #Transformer & {
    requiredLabels: {
        "core.opm.dev/workload-type": "stateless"
    }
    requiredResources: {
        "opm.dev/resources/workload@v0#Container": #ContainerResource
    }
}

#StatefulSetTransformer: #Transformer & {
    requiredLabels: {
        "core.opm.dev/workload-type": "stateful"
    }
    requiredResources: {
        "opm.dev/resources/workload@v0#Container": #ContainerResource
    }
}
```

A component can only have one `workload-type` value, so only one matches.

### Complementary Transformer (No Label Requirement)

```cue
#ServiceTransformer: #Transformer & {
    // No requiredLabels - matches any component with Expose trait
    requiredResources: {
        "opm.dev/resources/workload@v0#Container": #ContainerResource
    }
    requiredTraits: {
        "opm.dev/traits/network@v0#Expose": #ExposeTrait
    }
}
```

This matches alongside any workload transformer when component has Expose trait.

### Component with Multiple Matches

```cue
api: #Component & {
    #Container  // Has workload-type: "stateless" (required by user)
    #Expose     // Has Expose trait

    spec: {
        container: {image: "api:v1"}
        expose: {type: "ClusterIP", ports: [...]}
    }
}
```

**Matched transformers:**
1. `DeploymentTransformer` - matches (stateless + Container)
2. `ServiceTransformer` - matches (Container + Expose)

**Output:** `[Deployment, Service]`

## Acceptance Criteria

### Label-Based Matching

1. **Given** a Transformer with `requiredLabels: {"core.opm.dev/workload-type": "stateless"}`, **When** a component has that label (inherited from its Container Resource), **Then** the transformer matches.

2. **Given** a Transformer with `requiredLabels`, **When** a component is missing ANY required label or has a different value, **Then** the transformer does NOT match.

3. **Given** a Transformer with no `requiredLabels`, **When** a component exists, **Then** the transformer MAY match based on other requirements (requiredResources, requiredTraits, requiredPolicies).

### Resource/Trait/Policy Requirements

4. **Given** a Transformer with `requiredResources: {Container: ...}`, **When** a component has that resource in `#resources`, **Then** the resource requirement is satisfied.

5. **Given** a Transformer with `requiredTraits: {Expose: ...}`, **When** a component has that trait in `#traits`, **Then** the trait requirement is satisfied.

6. **Given** a Transformer with requirements, **When** a component is missing ANY required resource, trait, or policy, **Then** the transformer does NOT match.

### Matching Algorithm

7. **Given** a component with `#Container` resource (which defines `workload-type: "stateless"`), **When** matching against `DeploymentTransformer` (requires stateless) and `StatefulSetTransformer` (requires stateful), **Then** only `DeploymentTransformer` matches.

8. **Given** `ServiceTransformer` with `requiredTraits: {Expose: ...}` and no `requiredLabels`, **When** a component has Expose trait, **Then** `ServiceTransformer` matches regardless of workload-type.

9. **Given** a component with Container(stateless) + Expose trait, **When** matching, **Then** both `DeploymentTransformer` AND `ServiceTransformer` match (they are complementary).

### Conflict Detection

10. **Given** multiple transformers that match a component with identical requirements (same requiredLabels, requiredResources, requiredTraits, requiredPolicies), **When** matching, **Then** the system MUST error with "multiple exact transformer matches" listing the conflicting transformers.

11. **Given** transformers with different `requiredTraits` (e.g., DeploymentTransformer has none, ServiceTransformer requires Expose), **When** both match a component, **Then** they are considered complementary (not conflicting) and both execute.

### Transform Execution

12. **Given** matched transformers for a component, **When** transforms execute, **Then** each transformer receives the full component (not partitioned).

13. **Given** a transformer's `#transform.output`, **When** rendered, **Then** the output MUST be a list of platform resources (even for single-resource output).

14. **Given** multiple transformers matched to one component, **When** all transforms complete, **Then** outputs are concatenated into a single resource list.

### Unhandled Definitions

15. **Given** a component with a Trait not declared in any matched transformer's `requiredTraits` or `optionalTraits`, **When** matching completes, **Then** the system SHOULD warn about unhandled traits.

16. **Given** `--strict` mode enabled, **When** a component has unhandled traits, **Then** the system MUST error with the list of unhandled traits.

### No Match

17. **Given** no transformers match a component, **When** rendering, **Then** the system MUST error with component details and list of available transformers with their requirements.

### Provider Declaration

18. **Given** a Provider with transformers, **When** evaluated, **Then** `#declaredResources`, `#declaredTraits`, and `#declaredPolicies` list all supported FQNs from all transformers.

## Functional Requirements

### Label-Based Matching

- **FR-045**: Transformer MAY specify `requiredLabels: [string]: string` - label key-value pairs that a component MUST have to match.

- **FR-046**: Component labels are the union of `metadata.labels` from all attached `#resources`, `#traits`, and `#policies`.

- **FR-047**: A transformer matches a component when ALL of the following are true:
  - ALL `requiredLabels` are present on component with matching values
  - ALL `requiredResources` FQNs exist in `component.#resources`
  - ALL `requiredTraits` FQNs exist in `component.#traits`
  - ALL `requiredPolicies` FQNs exist in `component.#policies`

### Conflict Detection

- **FR-048**: When multiple transformers match a component with identical requirements (same requiredLabels, requiredResources, requiredTraits, requiredPolicies), the system MUST error.

- **FR-049**: Transformers with different requirements (e.g., different `requiredTraits`) are considered complementary and may both match the same component.

### Transform Execution

- **FR-050**: Each matched transformer receives the full component (components are not partitioned across transformers).

- **FR-051**: Outputs from multiple matched transformers are concatenated into a single resource list.

## Edge Cases

| Case | Behavior |
|------|----------|
| Component without `workload-type` label | Workload transformers requiring that label do not match |
| Multiple exact transformer matches | Error with list of conflicting transformers |
| Complementary transformers match | Both execute, outputs concatenated |
| Unhandled traits (normal mode) | Warning logged |
| Unhandled traits (`--strict` mode) | Error with list of unhandled traits |
| No transformers match | Error with component details and available transformers |
| Conflicting labels from definitions | CUE unification fails automatically |
