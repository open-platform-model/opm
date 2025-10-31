# OPM Definition Structure Reference

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-10-31

## Overview

This document provides a comprehensive reference for OPM's definition structure pattern. All OPM definitions follow a consistent two-level structure that separates OPM core versioning from element-specific versioning.

## Two-Level Structure

### Root Level (Fixed)

All OPM definitions have fixed root-level fields for OPM core API versioning:

```cue
apiVersion: "opm.dev/v1/core"  // Fixed for all v1 definitions
kind:       string              // Definition type identifier
```

**Purpose:**

- Identifies an object as an OPM v1 definition
- Specifies the type of definition (Unit, Trait, Blueprint, etc.)
- Provides Kubernetes-compatible manifest structure
- Enables tooling to recognize OPM objects

### Metadata Level (Context-Specific)

The metadata structure differs between **Definition types** and **Instance types**.

## Definition Types

Definition types are reusable, versioned schemas that can be imported and composed.

**Applies to:** UnitDefinition, TraitDefinition, BlueprintDefinition, PolicyDefinition, ModuleDefinition, Module

### Structure

```cue
#SomeDefinition: {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "SomeKind"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion!: string  // Element-specific version path
        name!:       string  // Definition name
        fqn:         string  // Computed: "\(apiVersion)#\(name)"
        description?: string
        labels?:      {...}
        annotations?: {...}
        // ... type-specific metadata fields
    }

    // Type-specific fields
    spec: {...}
}
```

### Field Descriptions

| Field | Level | Required | Description | Example |
|-------|-------|----------|-------------|---------|
| `apiVersion` | Root | Yes | Fixed OPM core version | `"opm.dev/v1/core"` |
| `kind` | Root | Yes | Definition type | `"Unit"`, `"Trait"`, `"Blueprint"` |
| `metadata.apiVersion` | Metadata | Yes | Element-specific version path | `"opm.dev/units/workload@v1"` |
| `metadata.name` | Metadata | Yes | Definition name (PascalCase) | `"Container"`, `"Replicas"` |
| `metadata.fqn` | Metadata | Computed | Fully Qualified Name | `"opm.dev/units/workload@v1#Container"` |
| `metadata.description` | Metadata | No | Human-readable description | `"Container unit for workloads"` |
| `metadata.labels` | Metadata | No | Classification labels | `{category: "workload"}` |
| `metadata.annotations` | Metadata | No | Additional metadata | `{source: "official"}` |

### FQN Computation

The FQN is **automatically computed** from metadata fields:

```cue
metadata: {
    apiVersion: "opm.dev/units/workload@v1"
    name:       "Container"
    fqn:        "\(apiVersion)#\(name)"  // Result: "opm.dev/units/workload@v1#Container"
}
```

**Key points:**

- FQN cannot be manually set
- FQN is derived value, always consistent
- FQN must match the pattern: `^([a-z0-9.-]+(?:/[a-z0-9.-]+)+)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$`

## Instance Types

Instance types represent specific instances of definitions within a module or deployment.

**Applies to:** ComponentDefinition, ScopeDefinition, ModuleRelease

### Structure

```cue
#SomeInstance: {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "SomeKind"

    // Metadata level: Instance identification only
    metadata: {
        name!: string  // Instance name
        namespace?: string  // Optional (required for ModuleRelease)
        description?: string
        labels?:      {...}
        annotations?: {...}
    }

    // Instance-specific fields
    spec: {...}
}
```

### Field Descriptions

| Field | Level | Required | Description | Example |
|-------|-------|----------|-------------|---------|
| `apiVersion` | Root | Yes | Fixed OPM core version | `"opm.dev/v1/core"` |
| `kind` | Root | Yes | Instance type | `"Component"`, `"Scope"`, `"ModuleRelease"` |
| `metadata.name` | Metadata | Yes | Instance name (lowercase) | `"api"`, `"database"` |
| `metadata.namespace` | Metadata | Conditional | Namespace (required for ModuleRelease) | `"production"` |
| `metadata.description` | Metadata | No | Human-readable description | `"API service component"` |
| `metadata.labels` | Metadata | No | Classification labels | `{tier: "backend"}` |
| `metadata.annotations` | Metadata | No | Additional metadata | `{team: "platform"}` |

**Note:** Instance types do NOT have:

- `metadata.apiVersion` (element-specific)
- `metadata.fqn`

## Complete Examples

### Example 1: UnitDefinition (Definition Type)

```cue
#Container: #UnitDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Unit"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion:  "opm.dev/units/workload@v1"
        name:        "Container"
        fqn:         "opm.dev/units/workload@v1#Container"  // Computed
        description: "Container unit for workload definitions"
        labels: {
            category: "workload"
            type:     "primitive"
        }
    }

    spec: {
        image!: string
        ports?: [...{
            containerPort!: int & >0 & <=65535
            protocol?:      "TCP" | "UDP" | *"TCP"
        }]
        env?: [...{
            name!:  string
            value!: string
        }]
    }
}
```

**Exported YAML:**

```yaml
apiVersion: opm.dev/core/v1
kind: Unit
metadata:
  apiVersion: opm.dev/units/workload@v1
  name: Container
  fqn: opm.dev/units/workload@v1#Container
  description: Container unit for workload definitions
  labels:
    category: workload
    type: primitive
spec:
  image: nginx:latest
  ports:
    - containerPort: 80
      protocol: TCP
```

### Example 2: TraitDefinition (Definition Type)

```cue
#Replicas: #TraitDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Trait"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion:  "opm.dev/traits/scaling@v1"
        name:        "Replicas"
        fqn:         "opm.dev/traits/scaling@v1#Replicas"  // Computed
        description: "Controls the number of replicas for a workload"
    }

    appliesTo: [...#UnitDefinition]  // Can be applied to any Unit

    spec: {
        count!: int & >0 & <=100
        autoscaling?: {
            enabled!:     bool
            minReplicas!: int & >0
            maxReplicas!: int & >0
            targetCPU?:   int & >0 & <=100
        }
    }
}
```

### Example 3: BlueprintDefinition (Definition Type)

```cue
#StatelessWorkload: #BlueprintDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Blueprint"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion:  "opm.dev/blueprints/workload@v1"
        name:        "StatelessWorkload"
        fqn:         "opm.dev/blueprints/workload@v1#StatelessWorkload"  // Computed
        description: "Standard stateless workload pattern with container and replicas"
    }

    composedUnits: [#Container]
    composedTraits: [#Replicas, #HealthCheck]

    spec: {
        // Blueprint-specific configuration
        defaults: {
            replicas: count: 1
            healthCheck: {
                liveness: {
                    httpGet: {path: "/healthz", port: 8080}
                    periodSeconds: 10
                }
            }
        }
    }
}
```

### Example 4: PolicyDefinition (Definition Type)

```cue
#ResourceLimitPolicy: #PolicyDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion:  "opm.dev/policies/workload@v1"
        name:        "ResourceLimit"
        fqn:         "opm.dev/policies/workload@v1#ResourceLimit"  // Computed
        description: "Enforces resource limits for component workloads"
        target:      "component"
    }

    enforcement: "strict"
    #spec: resourceLimit: {
        cpu?: {
            request!: string & =~"^[0-9]+m$"
            limit!:   string & =~"^[0-9]+m$"
        }
        memory?: {
            request!: string & =~"^[0-9]+[MG]i$"
            limit!:   string & =~"^[0-9]+[MG]i$"
        }
    }
}
```

### Example 5: ComponentDefinition (Instance Type)

```cue
api: #ComponentDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Component"

    // Metadata level: Instance identification only (no apiVersion or fqn)
    metadata: {
        name:        "api"
        description: "API service component"
        labels: {
            tier: "backend"
            team: "platform"
        }
    }

    spec: {
        // Component uses Container unit and Replicas trait
        container: {
            image: "myapp:v1.0.0"
            ports: [{containerPort: 8080}]
        }
        replicas: {
            count: 3
            autoscaling: {
                enabled:     true
                minReplicas: 2
                maxReplicas: 10
                targetCPU:   80
            }
        }
    }
}
```

### Example 6: ScopeDefinition (Instance Type)

```cue
backendScope: #ScopeDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Scope"

    // Metadata level: Instance identification only (no apiVersion or fqn)
    metadata: {
        name:        "backend"
        description: "Backend components scope"
    }

    appliesTo: {
        components: [api, database]
    }

    spec: {
        networkRules: {
            ingress: [{
                from:  [api]
                ports: [{protocol: "TCP", port: 5432}]
            }]
        }
    }
}
```

### Example 7: ModuleRelease (Instance Type)

```cue
prodRelease: #ModuleRelease & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "ModuleRelease"

    // Metadata level: Instance identification only (no apiVersion or fqn)
    metadata: {
        name:      "my-app-prod"
        namespace: "production"  // Required for ModuleRelease
        labels: {
            environment: "production"
            version:     "v1.0.0"
        }
    }

    moduleRef: {
        module:  "github.com/myorg/my-app@v1"
        version: "1.0.0"
    }

    values: {
        api: {
            image: "myapp:v1.0.0"
            replicas: count: 5
        }
        database: {
            storageSize: "100Gi"
        }
    }
}
```

## Comparison Table

| Aspect | Definition Types | Instance Types |
|--------|-----------------|----------------|
| **Purpose** | Reusable schemas | Specific instances |
| **Examples** | Unit, Trait, Blueprint, Policy | Component, Scope, ModuleRelease |
| **Root apiVersion** | `"opm.dev/v1/core"` | `"opm.dev/v1/core"` |
| **metadata.apiVersion** | ✅ Element-specific | ❌ Not present |
| **metadata.name** | ✅ Definition name (PascalCase) | ✅ Instance name (lowercase) |
| **metadata.fqn** | ✅ Computed from apiVersion + name | ❌ Not present |
| **Versioning** | Independent element versioning | No versioning (instances) |
| **Importable** | Yes (via FQN) | No |
| **Publishable** | Yes (to registries) | No |

## Rationale

### Why Two Levels?

1. **Kubernetes Compatibility**
   - Root-level `apiVersion` and `kind` match Kubernetes manifest structure
   - Familiar pattern for Kubernetes users
   - Compatible with existing tooling

2. **Separation of Concerns**
   - OPM core versioning separate from element/module versioning
   - Core schema can evolve independently from elements
   - Elements can version without breaking core

3. **Clean Exports**
   - When exported to YAML/JSON, definitions look like standard Kubernetes resources
   - Clear, readable structure
   - No surprises for users

4. **Flexible Versioning**
   - Elements version independently from the core schema
   - Breaking changes in elements don't affect core
   - Platform teams can control adoption pace

5. **Clear Instance vs Definition**
   - Instances don't need FQNs (they're not reusable definitions)
   - Reduces confusion about what can be imported
   - Explicit difference in structure

### Why Computed FQN?

1. **Consistency**
   - FQN always matches metadata.apiVersion + metadata.name
   - No possibility of mismatch
   - Single source of truth

2. **Simplicity**
   - Users don't manually construct FQNs
   - Less room for error
   - CUE validates correctness

3. **Type Safety**
   - CUE ensures FQN matches regex pattern
   - Validation happens at definition time
   - Errors caught early

## Migration from V0

V0 used a simpler structure with FQN at root level:

```cue
// V0 (old)
#Element: {
    apiVersion: "elements.opm.dev/core@v0"
    kind:       "Element"
    fqn:        "elements.opm.dev/core@v0#Element"
    // ...
}
```

V1 uses two-level structure:

```cue
// V1 (new)
#UnitDefinition: {
    apiVersion: "opm.dev/v1/core"
    kind:       "Unit"
    metadata: {
        apiVersion: "opm.dev/units/workload@v1"
        name:       "Container"
        fqn:        "opm.dev/units/workload@v1#Container"
    }
    // ...
}
```

See [MIGRATION_V0_TO_V1.md](MIGRATION_V0_TO_V1.md) for detailed migration guide.

## See Also

- [FQN Specification](FQN_SPEC.md) - Complete FQN format specification
- [Definition Types](DEFINITION_TYPES.md) - Deep dive into each definition type
- [Quick Reference](QUICK_REFERENCE.md) - One-page cheat sheet
- [Policy Definition](POLICY_DEFINITION.md) - Policy-specific structure details

---

**Document Version:** 1.0.0-draft
**Date:** 2025-10-31
