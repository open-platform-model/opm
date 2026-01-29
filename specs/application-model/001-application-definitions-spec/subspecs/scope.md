# Feature Specification: Scope Definition Specification

**Feature Branch**: `014-definition-scope-spec`  
**Created**: 2026-01-25  
**Status**: Draft  
**Input**: User description: "Create a new definition-spec for #Scope and reference it in the 001 scope subspec."

> **Feature Availability**: This definition is specified but currently **deferred** in CLI v1 to reduce initial complexity. It will be enabled in a future release.

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## Overview

This specification defines the #Scope definition used to apply Policies across groups of Components in a Module. It supersedes the scope subspec in `opm/specs/001-core-definitions-spec/subspecs/scope.md`.

Scopes are cross-cutting policy applicators. They centralize governance without duplicating policies across each component.

### Core Principle: Cross-Cutting Policy Application

Scopes exist to solve a specific problem: applying the same policy to multiple components. Without scopes, platform teams would need to add policies to each component individually.

```text
Without a shared scope:
    #scopes: {
        componentA: {#policies: {NetworkPolicy: ...}, appliesTo: {components: [#components.a]}}
        componentB: {#policies: {NetworkPolicy: ...}, appliesTo: {components: [#components.b]}}
        componentC: {#policies: {NetworkPolicy: ...}, appliesTo: {components: [#components.c]}}
    }

With Scopes:
    #scopes: {
        internalNetwork: {
            #policies: {NetworkPolicy: ...}
            appliesTo: {
                components: #allComponentsList  // All components in module
            }
        }
    }
```

### Scope Policy Application

Scopes are the sole attachment point for policies, allowing platform teams to apply governance to any set of components without touching component definitions.

## Schema

```cue
#Scope: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Scope"

    metadata: {
        name!:        string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Policies applied by this scope
    // Only policies with target: "scope" are allowed
    #policies: [PolicyFQN=string]: #Policy & {
        metadata: {
            name:   string | *PolicyFQN
            target: "scope"  // Enforced
        }
    }

    // Which components this scope applies to
    appliesTo: {
        // Select by component labels
        componentLabels?: [string]: #LabelsAnnotationsType
        
        // Select by direct component reference
        // Use #allComponentsList from module to apply to all components
        components: [...#Component]
    }

    // Merged spec from all policies
    spec: close(_allFields)
})
```

## appliesTo Selectors

Scopes use `appliesTo` to determine which components receive the scope's policies. Two selector types are available:

### 1. componentLabels

Selects components whose labels match the specified criteria:

```cue
#scopes: {
    backendNetwork: {
        #policies: {
            "opmodel.dev/policies/network@v0#InternalOnly": #InternalOnlyPolicy
        }
        
        appliesTo: {
            componentLabels: {
                "tier": {"tier": "backend"}
            }
        }
        
        spec: {
            internalOnly: {
                allowFrom: ["frontend", "api-gateway"]
            }
        }
    }
}
```

Components with `metadata.labels.tier: "backend"` receive the `InternalOnly` policy.

### 2. components

Selects specific components by direct reference:

```cue
#scopes: {
    criticalServices: {
        #policies: {
            "opmodel.dev/policies/reliability@v0#HighAvailability": #HAPolicy
        }
        
        appliesTo: {
            components: [#components.api, #components.database]
        }
        
        spec: {
            highAvailability: {
                minReplicas: 3
                maxUnavailable: 1
            }
        }
    }
}
```

Only `api` and `database` components receive the `HighAvailability` policy.

### Applying to All Components

To apply a scope to all components in the module, use `#allComponentsList` from the module. This is the module-wide policy pattern:

```cue
myModule: #Module & {
    #components: {
        api:      #Component & {...}
        worker:   #Component & {...}
        database: #Component & {...}
    }
    
    #scopes: {
        globalSecurity: {
            #policies: {
                "opmodel.dev/policies/security@v0#mTLS": #mTLSPolicy
            }
            
            appliesTo: {
                components: #allComponentsList  // References module's component list
            }
            
            spec: {
                mtls: {
                    enabled: true
                    mode: "STRICT"
                }
            }
        }
    }
}
```

Every component in the module receives the `mTLS` policy. The `#allComponentsList` is automatically computed by the module from `#components`.

### Selector Precedence

When multiple selectors are specified, they are combined with OR logic:

```cue
appliesTo: {
    componentLabels: {"tier": {"tier": "backend"}}
    components: [#components.special]
    // Matches: all backend components OR the special component
}
```

## Spec Flattening

Scope `spec` is derived from flattening all attached policy `#spec` fields:

```cue
_allFields: {
    if #policies != _|_ {
        for _, policy in #policies {
            if policy.#spec != _|_ {
                for k, v in policy.#spec {
                    (k): v
                }
            }
        }
    }
}

spec: close(_allFields)
```

## Examples

### Network Isolation Scope

```cue
myModule: #Module & {
    #components: {
        api:      #Component & {...}
        worker:   #Component & {...}
        database: #Component & {...}
    }
    
    #scopes: {
        databaseIsolation: {
            metadata: name: "database-isolation"
            
            #policies: {
                "opmodel.dev/policies/network@v0#NetworkPolicy": {
                    metadata: {
                        apiVersion: "opmodel.dev/policies/network@v0"
                        name:       "NetworkPolicy"
                        target:     "scope"
                    }
                    enforcement: {
                        mode:        "deployment"
                        onViolation: "block"
                    }
                    #spec: networkPolicy: {
                        ingress!:  [...{from: [...string], ports: [...int]}]
                        egress!:   [...{to: [...string], ports: [...int]}]
                    }
                }
            }
            
            appliesTo: {
                components: [#components.database]
            }
            
            spec: {
                networkPolicy: {
                    ingress: [{from: ["api", "worker"], ports: [5432]}]
                    egress: []  // No outbound connections
                }
            }
        }
    }
}
```

### Environment-Based Scope

```cue
myModule: #Module & {
    #components: {
        frontend: #Component & {
            metadata: labels: environment: "production"
            ...
        }
        api: #Component & {
            metadata: labels: environment: "production"
            ...
        }
        debug: #Component & {
            metadata: labels: environment: "development"
            ...
        }
    }
    
    #scopes: {
        productionSecurity: {
            metadata: name: "production-security"
            
            #policies: {
                "opmodel.dev/policies/security@v0#StrictMode": #StrictModePolicy
            }
            
            appliesTo: {
                componentLabels: {
                    "production": {environment: "production"}
                }
            }
            
            spec: {
                strictMode: {
                    readOnlyRootFilesystem: true
                    dropAllCapabilities: true
                }
            }
        }
    }
}
```

### Global Observability Scope

```cue
myModule: #Module & {
    #components: {
        frontend: #Component & {...}
        api:      #Component & {...}
        worker:   #Component & {...}
    }
    
    #scopes: {
        observability: {
            metadata: name: "global-observability"
            
            #policies: {
                "opmodel.dev/policies/observability@v0#Tracing": #TracingPolicy
                "opmodel.dev/policies/observability@v0#Metrics": #MetricsPolicy
            }
            
            appliesTo: {
                components: #allComponentsList  // All components
            }
            
            spec: {
                tracing: {
                    enabled: true
                    samplingRate: 0.1
                    exporter: "jaeger"
                }
                metrics: {
                    enabled: true
                    port: 9090
                    path: "/metrics"
                }
            }
        }
    }
}
```

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Apply governance across components (Priority: P1)

A Platform Operator wants to define a Scope that applies one or more policies to a group of components without editing each component.

**Why this priority**: This is the primary reason scopes exist and unlocks scalable governance.

**Independent Test**: Create a module with a scope that targets multiple components and verify that the scope policies are applied to all targeted components.

**Acceptance Scenarios**:

1. **Given** a Scope with two policies and a list of target components, **When** the module is evaluated, **Then** both policies apply to each targeted component.
2. **Given** a Scope with no matching components, **When** the module is evaluated, **Then** the scope is valid but has no effect.

---

### User Story 2 - Target components with selectors (Priority: P2)

A Module Author wants to target components by label or direct reference so that scopes are applied precisely.

**Why this priority**: Selectors make scopes practical for real modules without hardcoding every component name.

**Independent Test**: Define a scope with label selectors and ensure it selects the intended components.

**Acceptance Scenarios**:

1. **Given** components labeled with `tier: backend`, **When** a scope uses label selectors for `tier: backend`, **Then** only backend components are targeted.
2. **Given** a scope with both label selectors and explicit component references, **When** evaluated, **Then** components matching either selector are targeted.

---

### User Story 3 - Validate policy targeting (Priority: P2)

A Platform Operator wants invalid policies rejected when they are not scoped for scope-level enforcement.

**Why this priority**: Ensures governance rules are attached at the correct level and avoids misconfiguration.

**Independent Test**: Add a policy with a non-scope target to a scope and confirm validation fails.

**Acceptance Scenarios**:

1. **Given** a policy whose target is not `scope`, **When** it is placed in `#Scope.#policies`, **Then** validation fails with a target mismatch.

---

### Edge Cases

- Scope defines no selectors but includes policies.
- Scope selectors reference non-existent components.
- Policies within the same scope define conflicting spec fields.
- Multiple scopes apply the same policy to the same component.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a `#Scope` definition as a closed struct.
- **FR-002**: `#Scope` MUST require `metadata.name` and allow optional labels and annotations.
- **FR-003**: `#Scope` MUST define a `#policies` map that only accepts policies with `target: "scope"`.
- **FR-004**: `#Scope` MUST define `appliesTo` for selecting components.
- **FR-005**: `appliesTo.components` MUST support direct component references and module-wide lists.
- **FR-006**: `appliesTo.componentLabels` MUST support label-based selection.
- **FR-007**: When both selector types are provided, they MUST be combined with OR logic.
- **FR-008**: `#Scope.spec` MUST be derived from flattening all attached policy `#spec` fields.
- **FR-009**: Conflicting policy specs in the same scope MUST fail validation.
- **FR-010**: Components targeted by a scope MUST receive the scope's policies as part of module evaluation.

### Key Entities *(include if feature involves data)*

- **Scope**: Cross-cutting policy applicator that targets a group of components.
- **Policy**: Governance definition applied by a scope.
- **AppliesTo Selector**: Selector block that determines component targets.
- **Component**: Module element that receives policies via scopes.

## Assumptions

- Modules expose a component list and component labels for scope selection.
- Policies expose a target field and a spec block that can be merged.

## Dependencies

- Policy definition specification
- Component definition specification

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Independent reviewers reach identical pass/fail outcomes for 10 sample scope definitions.
- **SC-002**: 100% of policies with non-scope targets are rejected when attached to a scope.
- **SC-003**: 90% of module authors can correctly target a subset of components using selectors in under 15 minutes using only this specification.
- **SC-004**: A validation suite detects all conflicting policy specs within a scope.

## Acceptance Criteria

### Policy Target Validation

1. **Given** a Policy with `target: "scope"`, **When** added to `#Scope.#policies`, **Then** validation succeeds.

2. **Given** a Policy with a non-scope target, **When** added to `#Scope.#policies`, **Then** validation fails (target mismatch).

### appliesTo Selectors

1. **Given** a Scope with `appliesTo.components: #allComponentsList`, **When** module has 3 components, **Then** scope applies to all 3 components.

2. **Given** a Scope with `appliesTo.components: [#components.api, #components.worker]`, **When** module has 3 components, **Then** scope applies only to api and worker.

3. **Given** a Scope with `appliesTo.componentLabels: {backend: {tier: "backend"}}`, **When** 2 of 3 components have `tier: "backend"`, **Then** scope applies to those 2 components.

4. **Given** a Scope with both `componentLabels` and `components`, **When** evaluated, **Then** selectors are combined with OR logic.

### Spec Flattening

1. **Given** a Scope with 2 policies defining different spec fields, **When** evaluated, **Then** `spec` contains fields from both policies.

2. **Given** a Scope with policies having conflicting spec values, **When** evaluated, **Then** CUE fails with unification error.

### Edge Cases

1. **Given** a Scope with `appliesTo.componentLabels` matching no components, **When** evaluated, **Then** scope is valid but has no effect.

2. **Given** a Scope with empty `#policies: {}`, **When** evaluated, **Then** scope is valid but provides no policy application.

3. **Given** a Scope with empty `appliesTo.components: []`, **When** evaluated, **Then** scope applies to nothing (valid but no effect).

## Additional Edge Cases

| Case | Behavior |
|------|----------|
| Policy with a non-scope target | Validation error |
| `appliesTo.components` empty list `[]` | Valid, scope applies to nothing |
| `appliesTo.components: #allComponentsList` | Scope applies to all module components |
| `componentLabels` matches no components | Valid, scope has no effect |
| `components` references non-existent component | CUE reference error |
| Empty `#policies` | Valid, no policies applied |
| Both `componentLabels` and `components` specified | OR combination |
| Conflicting policy specs | CUE unification error |
| Multiple scopes apply to same component | All scope policies are applied |

## Design Rationale

### Why Separate from Component Policies?

Scopes exist because:

1. **DRY principle** - Define once, apply to many
2. **Separation of concerns** - Platform teams manage cross-cutting policies separately from component definitions
3. **Auditability** - Clear visibility into what policies apply across components

### Why Target Validation?

The `target` field prevents misuse:

- Component policies are designed for single-component constraints
- Scope policies are designed for cross-cutting concerns
- The semantics may differ (e.g., scope policies might aggregate differently)

### Why OR Logic for Multiple Selectors?

OR combination is more intuitive:

- "Apply to backend components OR these specific critical services"
- AND would be too restrictive: "must match ALL criteria"
- Users can achieve AND by using more specific label selectors

## Future Considerations

The following are intentionally excluded and may be added later:

- **Negative selectors**: `excludeComponents`, `excludeLabels`
- **Selector expressions**: Complex boolean expressions for component matching
- **Scope inheritance**: Scopes that extend other scopes
- **Scope ordering**: Explicit ordering when multiple scopes apply to the same component
