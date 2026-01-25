# Scope Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2025-12-26

## Overview

This document defines how scopes apply policies to groups of components within OPM modules. Scopes are cross-cutting policy applicators - they enable platform teams to apply governance rules across multiple components without modifying each component individually.

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
    apiVersion: "opm.dev/core/v0"
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
            "opm.dev/policies/network@v0#InternalOnly": #InternalOnlyPolicy
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
            "opm.dev/policies/reliability@v0#HighAvailability": #HAPolicy
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
                "opm.dev/policies/security@v0#mTLS": #mTLSPolicy
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
                "opm.dev/policies/network@v0#NetworkPolicy": {
                    metadata: {
                        apiVersion: "opm.dev/policies/network@v0"
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
                "opm.dev/policies/security@v0#StrictMode": #StrictModePolicy
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
                "opm.dev/policies/observability@v0#Tracing": #TracingPolicy
                "opm.dev/policies/observability@v0#Metrics": #MetricsPolicy
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

## Functional Requirements

### Policy Restriction

- **FR-074**: Scope MUST only accept Policies with `target: "scope"` in `#policies`.

### appliesTo Requirement

- **FR-075**: Scope MUST have `appliesTo` to specify which components it affects.

### Selector Types

- **FR-076**: `appliesTo.componentLabels` selects components by label matching.

- **FR-077**: `appliesTo.components` selects components by direct reference; use `#allComponentsList` from module to apply to all components.

### Spec Derivation

- **FR-079**: Scope `spec` MUST be derived from flattening all attached policy `#spec` fields.

## Edge Cases

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
