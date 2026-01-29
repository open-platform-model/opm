# Component Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2025-12-26

> **Feature Availability**: This definition is **enabled** in CLI v1.

## Overview

This document defines how components are composed within OPM modules. Components are the fundamental units of composition - they combine resources, traits, and blueprints into a unified, deployable unit.

### Core Principle: Composition via Unification

Components use CUE unification to merge specifications from multiple definitions:

```cue
#Component: {
    _allFields: {
        for _, resource in #resources {
            if resource.#spec != _|_ {
                for k, v in resource.#spec {
                    (k): v
                }
            }
        }
        if #traits != _|_ {
            for _, trait in #traits {
                if trait.#spec != _|_ {
                    for k, v in trait.#spec {
                        (k): v
                    }
                }
            }
        }
        if #blueprints != _|_ {
            for _, blueprint in #blueprints {
                if blueprint.#spec != _|_ {
                    for k, v in blueprint.#spec {
                        (k): v
                    }
                }
            }
        }
    }
    spec: close({
        _allFields
        ...
    })
}
```

This enables:

- **Separation of concerns** - Each definition type focuses on one aspect
- **Reusability** - Definitions can be shared across components
- **Type safety** - CUE validates the merged result

### Component-Module Relationship

Components are instantiated within modules via `#Module.#components`:

```cue
#Module & {
    metadata: {
        defaultNamespace: "production"
    }
    
    #components: {
        api: #Component & {
            workload.#Container

            spec: {
                container: {
                    name: "api"
                    image: "api:v1.0.0"
                }
            }
        }
    }
}
```

## Schema

```cue
#Component: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Component"

    metadata: {
        name!: string
        
        // Component labels - unified from all attached resources, traits
        // Labels are inherited from definitions and used for transformer matching.
        // If definitions have conflicting labels, CUE unification will fail (automatic validation).
        labels: #LabelsAnnotationsType & {
            // Standard label for component name
            "component.opmodel.dev/name": name

            // Inherit labels from resources
            for _, resource in #resources if resource.metadata.labels != _|_ {
                for lk, lv in resource.metadata.labels {
                    (lk): lv
                }
            }

            // Inherit labels from traits
            if #traits != _|_ {
                for _, trait in #traits if trait.metadata.labels != _|_ {
                    for lk, lv in trait.metadata.labels {
                        (lk): lv
                    }
                }
            }
        }
        
        // Component annotations - unified from all attached resources, traits
        // If definitions have conflicting annotations, CUE unification will fail (automatic validation).
        annotations?: {
            [string]: string | int | bool | [...(string | int | bool)]

            // Inherit annotations from resources
            for _, resource in #resources if resource.metadata.annotations != _|_ {
                for ak, av in resource.metadata.annotations {
                    (ak): av
                }
            }

            // Inherit annotations from traits
            if #traits != _|_ {
                for _, trait in #traits if trait.metadata.annotations != _|_ {
                    for ak, av in trait.metadata.annotations {
                        (ak): av
                    }
                }
            }
        }
    }

    // Resources applied to this component
    #resources: #ResourceMap

    // Traits applied to this component (optional)
    #traits?: #TraitMap

    // Blueprints applied to this component (optional)
    #blueprints?: #BlueprintMap

    // Merged spec from all definitions
    spec: close({
        _allFields
    })

    // Computed status
    status: {
        resourceCount: len(#resources)
        traitCount?: {if #traits != _|_ {len(#traits)}}
        blueprintCount?: {if #blueprints != _|_ {len(#blueprints)}}
    }
})
```

## Spec Merging Algorithm

The component's `spec` field is computed by merging `#spec` from all attached definitions:

```cue
_allFields: {
    // 1. Collect from resources
    for _, resource in #resources {
        if resource.#spec != _|_ {
            for k, v in resource.#spec {
                (k): v
            }
        }
    }
    
    // 2. Collect from traits
    if #traits != _|_ {
        for _, trait in #traits {
            if trait.#spec != _|_ {
                for k, v in trait.#spec {
                    (k): v
                }
            }
        }
    }
    
    // 3. Collect from blueprints
    if #blueprints != _|_ {
        for _, blueprint in #blueprints {
            if blueprint.#spec != _|_ {
                for k, v in blueprint.#spec {
                    (k): v
                }
            }
        }
    }
}

spec: close({
    _allFields
})
```

### Why `close()` without Spread Operator?

The `spec` uses `close({_allFields})` to:

1. **Type safety**: Prevent typos in field names from silently being ignored
2. **Transformer validation**: Allow transformers to validate against known fields
3. **Direct field inclusion**: All fields from `_allFields` are directly included in the spec without the need for spread operator

## Label Inheritance

Component labels are the union of labels from:

1. Labels explicitly set on the component
2. Labels from all `#resources`
3. Labels from all `#traits`

```cue
metadata: {
    labels: {
        // Explicit component labels
        [string]: string | int | bool | [...(string | int | bool)]

        // Inherit from resources
        for _, resource in #resources if resource.metadata.labels != _|_ {
            for lk, lv in resource.metadata.labels {
                (lk): lv
            }
        }

        // Inherit from traits
        if #traits != _|_ {
            for _, trait in #traits if trait.metadata.labels != _|_ {
                for lk, lv in trait.metadata.labels {
                    (lk): lv
                }
            }
        }
    }
}
```

### Conflict Detection

If two definitions provide the same label key with different values, CUE unification fails automatically:

```cue
// Resource A
metadata: labels: "tier": "frontend"

// Trait B
metadata: labels: "tier": "backend"

// Result: CUE error - conflicting values "frontend" and "backend"
```

## Examples

### Basic Component

```cue
import "opmodel.dev/resources/workload@v0"
import "opmodel.dev/traits/scaling@v0"

api: #Component & {
    workload.#Container
    scaling.#Replicas

    // Automatically populated by including the definitions above
    // #resources: {
    //     (workload.#Container.metadata.fqn): workload.#Container
    // }
    //
    // #traits: {
    //     (scaling.#Replicas.metadata.fqn): scaling.#Replicas
    // }
    
    spec: {
        container: {
            image: "api:v1.0.0"
            ports: [{containerPort: 8080}]
        }
        replicas: 3
    }
}
```

### Component with Blueprint

```cue
import "opmodel.dev/blueprints/web@v0"

frontend: #Component & {
    #blueprints: {
        (web.#WebService.metadata.fqn): web.#WebService
    }
    
    // Blueprint provides: Container + Replicas + HealthCheck + Expose
    spec: {
        container: {image: "frontend:v2.0.0"}
        replicas: 2
        healthCheck: {path: "/health", port: 8080}
        expose: {type: "ClusterIP", ports: [{port: 80, targetPort: 8080}]}
    }
}
```

### Component in Module Context

```cue
myModule: #Module & {
    metadata: {
        apiVersion:       "example.com/modules@v0"
        name:             "MyApp"
        version:          "1.0.0"
        defaultNamespace: "production"
    }
    
    #components: {
        // name defaults to "api" (from map key)
        api: #Component & {
            #resources: {...}
            spec: {...}
        }
        
        // name defaults to "worker" (from map key)
        worker: #Component & {
            #resources: {...}
            spec: {...}
        }
    }
}
```

## Acceptance Criteria

### Spec Merging

1. **Given** a Component with a Container resource and Replicas trait, **When** evaluated, **Then** `spec` contains both `container` and `replicas` fields.

2. **Given** a Component with a Blueprint that composes Container + HealthCheck, **When** evaluated, **Then** `spec` contains `container` and `healthCheck` fields.

3. **Given** a Component with a Policy defining `securityContext`, **When** evaluated, **Then** `spec` contains `securityContext` field.

4. **Given** definitions with overlapping field names and compatible values, **When** evaluated, **Then** CUE unifies the values.

5. **Given** definitions with overlapping field names and incompatible values, **When** evaluated, **Then** CUE fails with unification error.

### Label Inheritance

1. **Given** a Resource with `labels: {"tier": "backend"}`, **When** attached to a Component, **Then** Component has `metadata.labels.tier: "backend"`.

2. **Given** a Resource and Trait with the same label key and same value, **When** attached to a Component, **Then** Component has that label (unified).

3. **Given** a Resource and Trait with the same label key but different values, **When** attached to a Component, **Then** CUE fails with conflicting values error.

### Resource Requirement

1. **Given** a Component with empty `#resources: {}`, **When** evaluated, **Then** validation SHOULD fail (currently deferred in implementation).

2. **Given** a Component with at least one Resource, **When** evaluated, **Then** validation succeeds.

### Module Context

1. **Given** a Component defined in `#Module.#components` with key "api", **When** no explicit name provided, **Then** `metadata.name` defaults to "api".

2. **Given** a Component with explicit `metadata.name: "custom"`, **When** in a Module with map key "api", **Then** Component uses "custom".

### Status Computation

1. **Given** a Component with 2 resources, 3 traits, and 1 blueprint, **When** evaluated, **Then** `status` shows correct counts.

## Functional Requirements

### Spec Merging

- **FR-6-001**: `#Component` merges specs from `#resources`, `#traits`, and `#blueprints` into a unified `spec` field.
- **FR-6-002**: Component `spec` MUST use `close()` for type safety with transformer validation.
- **FR-6-003**: Component MUST merge `#spec` from all attached `#resources`, `#traits`, and `#blueprints` into unified `spec` field.
- **FR-6-004**: Component `spec` MUST use `close({_allFields})` to include fields from compositions while maintaining type safety.
- **FR-6-005**: Component labels MUST be the union of labels from the component itself plus all attached definitions (`#resources`, `#traits`).
- **FR-6-006**: Conflicting labels from definitions (same key, different value) MUST cause CUE unification failure.
- **FR-6-007**: Component SHOULD have at least one Resource in `#resources` (validation currently deferred in code).
- **FR-6-008**: Component `status` MUST compute counts for resources, traits, and blueprints.
- **FR-6-009**: When component is defined in `#Module.#components`, component name defaults to the map key via `metadata: {name: string | *Id}`.
- **FR-6-010**: Component metadata MUST automatically add standard label `"component.opmodel.dev/name"`.
- **FR-6-011**: Component MUST inherit annotations from attached resources and traits.

## Edge Cases

| Case | Behavior |
|------|----------|
| Empty `#resources` | Validation SHOULD error (currently deferred in code) |
| Empty `#traits`, `#blueprints` | Valid (all optional) |
| Conflicting labels | CUE unification error |
| Conflicting annotations | CUE unification error |
| Conflicting spec fields (incompatible) | CUE unification error |
| Conflicting spec fields (compatible) | CUE unifies values |
| No explicit component name in module | Defaults to map key |
| Explicit name overrides default | Explicit value used |
| Blueprint expands to same resource as direct | CUE unifies (if compatible) |

## Success Criteria

- **SC-001**: All core definition types validate with `cue vet` when given valid input.
- **SC-002**: Invalid definitions are rejected with clear error messages.
- **SC-003**: Policy target mismatches are caught by CUE unification.
- **SC-004**: Component `spec` correctly merges fields from all attached definitions.

## Design Rationale

### Why Merge into Single `spec`?

The merged `spec` provides:

1. **Single source of truth** - Users configure one `spec` object, not multiple
2. **Validation** - CUE validates the complete configuration together
3. **Transformer simplicity** - Transformers receive a unified spec, not scattered fields

### Why Require at Least One Resource?

A component without a resource has nothing to deploy. Resources are the "nouns" - without something that exists, there is nothing to modify (traits)

### Why Inherit Labels from Definitions?

Labels enable transformer matching. By inheriting from definitions:

1. **Automatic categorization** - A `#Container` resource can label the component as `workload-type: stateless`
2. **No duplication** - Labels are defined once in the definition, not repeated in every component
3. **Consistency** - All components using a definition get consistent labels
