# Trait Definition Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-10-31

## Overview

Traits are behavioral modifiers in OPM that define **how components behave** at runtime. While Units describe "what exists," Traits describe operational concerns like scaling, health checking, networking, and resource management.

### Core Principles

- **Behavioral**: Traits modify how components run, not what they are
- **Attachable**: Traits are applied to Units, not used standalone
- **Optional**: Traits provide optional behaviors that enhance base functionality
- **Type-constrained**: Each trait declares which Units it can modify via `appliesTo`
- **Composable**: Multiple traits can be applied to the same component

### What Traits Represent

Traits can describe:

- **Scaling**: Replica counts, autoscaling policies
- **Networking**: Service exposure, ingress, traffic routing
- **Health**: Liveness probes, readiness checks, startup probes
- **Security**: TLS configuration, pod security contexts, encryption
- **Resource Management**: CPU/memory limits, storage quotas
- **Restart Policies**: How workloads restart on failure
- **Update Strategies**: Rolling updates, blue-green deployments

### Traits vs Units

| Aspect | Traits | Units |
|--------|--------|-------|
| **Purpose** | Define "how it behaves" | Define "what exists" |
| **Independence** | Applied to Units | Standalone building blocks |
| **appliesTo field** | ✅ Required | ❌ Not present |
| **Examples** | Replicas, HealthCheck, Expose | Container, Volume, ConfigMap |

---

## Trait Definition Structure

Every Trait follows this structure:

```cue
#TraitDefinition: close({
    // Root level: OPM core versioning
    apiVersion: "opm.dev/core/v1"
    kind:       "Trait"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion!:  #NameType                          // Element-specific version path
        name!:        #NameType                          // Trait name (PascalCase)
        fqn:          #FQNType & "\(apiVersion)#\(name)" // Computed FQN
        description?: string                             // Human-readable description
        labels?:      #LabelsAnnotationsType             // For categorization/filtering
        annotations?: #LabelsAnnotationsType             // For behavior hints
    }

    // OpenAPIv3-compatible schema defining the trait's spec structure
    // Field name is auto-derived from metadata.name using camelCase
    #spec!: (strings.ToCamel(metadata.name)): _

    // Units that this trait can be applied to (full CUE references)
    appliesTo!: [...#UnitDefinition]
})
```

### Hybrid Structure

Traits use OPM's two-level structure (same as Units):

**Root Level (Fixed):**

- `apiVersion: "opm.dev/core/v1"` - Fixed OPM core version
- `kind: "Trait"` - Identifies this as a Trait definition

**Metadata Level (Element-Specific):**

- `metadata.apiVersion` - Element-specific version (e.g., `"opm.dev/traits/scaling@v1"`)
- `metadata.name` - Trait name (e.g., `"Replicas"`)
- `metadata.fqn` - Computed as `"\(apiVersion)#\(name)"`

This structure provides:

- **Kubernetes compatibility**: Root fields match K8s manifest structure
- **Independent versioning**: Traits can version separately from OPM core
- **Clean exports**: Definitions export as standard K8s-like resources

See [Definition Structure](DEFINITION_STRUCTURE.md) for complete details.

---

## Field Reference

### apiVersion (Root Level)

**Type:** `string`
**Required:** Yes
**Fixed Value:** `"opm.dev/core/v1"`

Identifies this object as an OPM core v1 definition. This field is fixed for all v1 traits and represents the OPM core schema version, not the trait's own version.

```cue
apiVersion: "opm.dev/core/v1"  // Always this value for v1 traits
```

### kind (Root Level)

**Type:** `string`
**Required:** Yes
**Fixed Value:** `"Trait"`

Identifies this object as a Trait definition (as opposed to Unit, Blueprint, Component, etc.).

```cue
kind: "Trait"  // Always this value for traits
```

### metadata.apiVersion (Metadata Level)

**Type:** `#NameType`
**Required:** Yes
**Pattern:** `<domain>/<category>/<subcategory>@v<major>`

The element-specific version path for this trait. This allows the trait to version independently from the OPM core schema.

**Examples:**

```cue
apiVersion: "opm.dev/traits/scaling@v1"
apiVersion: "opm.dev/traits/networking@v1"
apiVersion: "opm.dev/traits/health@v1"
apiVersion: "opm.dev/traits/security@v1"
apiVersion: "github.com/myorg/traits/custom@v1"
```

**Best Practices:**

- Use semantic grouping: `domain/traits/category@version`
- Official OPM traits use `opm.dev/traits/*`
- Third-party traits use your domain or GitHub path
- Major version in @v format (e.g., `@v1`, `@v2`)

### metadata.name (Metadata Level)

**Type:** `#NameType`
**Required:** Yes
**Pattern:** PascalCase, starts with uppercase letter

The trait's name, which must be unique within the `metadata.apiVersion` namespace.

**Examples:**

```cue
name: "Replicas"
name: "Expose"
name: "HealthCheck"
name: "RestartPolicy"
```

**Naming Rules:**

- Must start with uppercase letter
- Use PascalCase (e.g., `HealthCheck`, not `health_check`)
- Be descriptive, not abbreviated (e.g., `Replicas`, not `Reps`)
- Describe the behavior, not the platform (e.g., `Expose`, not `K8sService`)

### metadata.fqn (Metadata Level)

**Type:** `#FQNType`
**Required:** Computed (not manually set)
**Pattern:** `<repo-path>@v<major>#<Name>`

The Fully Qualified Name, automatically computed from `metadata.apiVersion` and `metadata.name`.

```cue
metadata: {
    apiVersion: "opm.dev/traits/scaling@v1"
    name:       "Replicas"
    fqn:        "\(apiVersion)#\(name)"  // Result: "opm.dev/traits/scaling@v1#Replicas"
}
```

**Key Points:**

- **Never manually set** - always use the interpolation pattern
- **Globally unique** - serves as the trait's identifier throughout OPM
- **Used for indexing** - components use FQN as map keys
- **Matches regex**: `^([a-z0-9.-]+(?:/[a-z0-9.-]+)+)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$`

### metadata.description (Metadata Level)

**Type:** `string`
**Required:** No
**Purpose:** Human-readable explanation of the trait's behavior

```cue
description: "Controls the number of replicas for a workload"
description: "Exposes a workload via a service"
description: "Configures liveness and readiness probes"
```

**Best Practices:**

- Keep concise (1-2 sentences)
- Explain the behavior being modified
- Mention key capabilities or constraints
- Use sentence case with period

### metadata.labels (Metadata Level)

**Type:** `#LabelsAnnotationsType` (`[string]: string | int | bool | array`)
**Required:** No
**Purpose:** Categorization and filtering for OPM tooling

Labels are used by the OPM system for:

- **Categorization**: Grouping traits by type or purpose
- **Transformer matching**: Selecting appropriate transformers
- **Registry filtering**: Finding traits in catalogs
- **Validation**: Enforcing organizational policies

**Examples:**

```cue
labels: {
    "core.opm.dev/category": "scaling"
}

labels: {
    "core.opm.dev/category": "networking"
    "core.opm.dev/type":   "exposure"
}

labels: {
    "myorg.com/criticality": "high"
    "myorg.com/team":        "platform"
}
```

**Recommended Labels:**

- `core.opm.dev/category` - Trait category (scaling, networking, health, security, restart)
- `core.opm.dev/type` - Specific category within type
- Organization-specific labels with your domain prefix

### metadata.annotations (Metadata Level)

**Type:** `#LabelsAnnotationsType`
**Required:** No
**Purpose:** Additional metadata NOT used for selection/matching

Annotations provide hints to providers/transformers but are not used for matching logic.

**Examples:**

```cue
annotations: {
    "opm.dev/documentation": "https://opm.dev/docs/traits/replicas"
    "opm.dev/source":        "official"
}

annotations: {
    "myorg.com/owner":       "platform-team"
    "myorg.com/review-date": "2025-12-31"
}
```

### #spec (Specification Schema)

**Type:** CUE schema
**Required:** Yes
**Purpose:** OpenAPIv3-compatible schema defining the trait's configuration structure

The `#spec` field defines what configuration users must provide when applying this trait to a component.

**Key Characteristics:**

- **Auto-named**: Field name is `strings.ToCamel(metadata.name)`
  - `"Replicas"` → `replicas: {...}`
  - `"HealthCheck"` → `healthCheck: {...}`
  - `"RestartPolicy"` → `restartPolicy: {...}`
- **Uses # prefix**: Allows incomplete/template values (inconcrete fields)
- **OpenAPIv3-compatible**: Can be converted to OpenAPI schemas
- **Arbitrary structure**: Can be any valid CUE type (struct, map, list, constraint)

**Examples:**

```cue
// Simple constraint
#spec: replicas: int & >=1 & <=1000

// Struct with fields
#spec: healthCheck: {
    liveness?: {...}
    readiness?: {...}
}

// Enum
#spec: restartPolicy: "Always" | "OnFailure" | "Never"
```

### appliesTo (Trait-Specific)

**Type:** `[...#UnitDefinition]`
**Required:** Yes
**Purpose:** Declares which Units this trait can modify

The `appliesTo` field is **unique to Traits** and defines type constraints for trait application.

**Key Characteristics:**

- **Full CUE references**: Uses actual Unit definition references, NOT FQN strings
- **Type safety**: CUE validates trait compatibility at compile time
- **Multiple units**: Can specify multiple compatible units
- **Validation**: Components must satisfy appliesTo constraints

**Examples:**

```cue
// Single unit
appliesTo: [#ContainerUnit]

// Multiple units
appliesTo: [#ContainerUnit, #PodUnit]

// Any unit (discouraged - too broad)
appliesTo: [...#UnitDefinition]
```

**Important:** Use **full CUE references** (e.g., `#ContainerUnit`), NOT FQN strings (e.g., `"opm.dev/units/workload@v1#Container"`).

---

## Complete Examples

### Example 1: Replicas Trait (Simple Constraint)

```cue
// Schema definition - simple integer constraint
#ReplicasSchema: int & >=1 & <=1000 | *1

// Trait definition
#ReplicasTrait: close(#TraitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Trait"

    metadata: {
        apiVersion:  "opm.dev/traits/scaling@v1"
        name:        "Replicas"
        fqn:         "opm.dev/traits/scaling@v1#Replicas"
        description: "Controls the number of replicas for a workload"
        labels: {
            "core.opm.dev/category": "scaling"
            "core.opm.dev/type": "replication"
        }
    }

    // Applies only to Container units
    appliesTo: [#ContainerUnit]

    // Creates field: replicas: int & >=1 & <=1000
    #spec: replicas: #ReplicasSchema
})

// Helper for component composition
#Replicas: close(#ComponentDefinition & {
    #traits: {(#ReplicasTrait.metadata.fqn): #ReplicasTrait}
})
```

**Usage in Component:**

```cue
webServer: #ComponentDefinition & {
    metadata: name: "web-server"

    #Container  // Unit
    #Replicas   // Trait

    spec: {
        container: {
            image: "nginx:latest"
        }
        replicas: 3  // From Replicas trait
    }
}
```

### Example 2: Expose Trait (Complex Object Schema)

```cue
// Schema definition
#ExposeSchema: close({
    type!:    "ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName" | *"ClusterIP"
    port!:    int & >=1 & <=65535
    protocol: "TCP" | "UDP" | *"TCP"
    hostname?: string
    annotations?: [string]: string
})

// Trait definition
#ExposeTrait: close(#TraitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Trait"

    metadata: {
        apiVersion:  "opm.dev/traits/networking@v1"
        name:        "Expose"
        fqn:         "opm.dev/traits/networking@v1#Expose"
        description: "Exposes a workload via a service"
        labels: {
            "core.opm.dev/category": "networking"
            "core.opm.dev/type":   "exposure"
        }
    }

    // Can be applied to Container units
    appliesTo: [#ContainerUnit]

    // Creates field: expose: #ExposeSchema
    #spec: expose: #ExposeSchema
})

// Helper for component composition
#Expose: close(#ComponentDefinition & {
    #traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
})
```

**Usage in Component:**

```cue
api: #ComponentDefinition & {
    metadata: name: "api"

    #Container
    #Replicas
    #Expose  // Networking trait

    spec: {
        container: {
            image: "api:v1"
            ports: {
                http: {containerPort: 8080}
            }
        }
        replicas: 3
        expose: {
            type:     "LoadBalancer"
            port:     80
            protocol: "TCP"
        }
    }
}
```

### Example 3: HealthCheck Trait (Nested Structure)

```cue
// Schema definition
#HealthCheckSchema: close({
    liveness?: {
        httpGet?: {
            path!: string
            port!: int & >0 & <65536
        }
        exec?: {
            command!: [...string]
        }
        initialDelaySeconds?: int & >=0 | *0
        periodSeconds?:       int & >0 | *10
        timeoutSeconds?:      int & >0 | *1
        failureThreshold?:    int & >0 | *3
    }
    readiness?: {
        httpGet?: {
            path!: string
            port!: int & >0 & <65536
        }
        exec?: {
            command!: [...string]
        }
        initialDelaySeconds?: int & >=0 | *0
        periodSeconds?:       int & >0 | *10
        timeoutSeconds?:      int & >0 | *1
        failureThreshold?:    int & >0 | *3
    }
    startup?: {
        httpGet?: {
            path!: string
            port!: int & >0 & <65536
        }
        initialDelaySeconds?: int & >=0 | *0
        periodSeconds?:       int & >0 | *10
        failureThreshold?:    int & >0 | *30
    }
})

// Trait definition
#HealthCheckTrait: close(#TraitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Trait"

    metadata: {
        apiVersion:  "opm.dev/traits/health@v1"
        name:        "HealthCheck"
        fqn:         "opm.dev/traits/health@v1#HealthCheck"
        description: "Configures liveness, readiness, and startup probes"
        labels: {
            "core.opm.dev/category": "workload"
            "core.opm.dev/type":     "health"
        }
    }

    appliesTo: [#ContainerUnit]

    #spec: healthCheck: #HealthCheckSchema
})

#HealthCheck: close(#ComponentDefinition & {
    #traits: {(#HealthCheckTrait.metadata.fqn): #HealthCheckTrait}
})
```

**Usage:**

```cue
api: #ComponentDefinition & {
    metadata: name: "api"

    #Container
    #HealthCheck

    spec: {
        container: {
            image: "api:v1"
        }
        healthCheck: {
            liveness: {
                httpGet: {
                    path: "/healthz"
                    port: 8080
                }
                initialDelaySeconds: 30
                periodSeconds:       10
            }
            readiness: {
                httpGet: {
                    path: "/ready"
                    port: 8080
                }
                initialDelaySeconds: 5
                periodSeconds:       5
            }
        }
    }
}
```

### Example 4: RestartPolicy Trait (Enum)

```cue
// Simple enum schema
#RestartPolicySchema: "Always" | "OnFailure" | "Never" | *"Always"

#RestartPolicyTrait: close(#TraitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Trait"

    metadata: {
        apiVersion:  "opm.dev/traits/restart@v1"
        name:        "RestartPolicy"
        fqn:         "opm.dev/traits/restart@v1#RestartPolicy"
        description: "Controls how workloads restart on failure"
        labels: {
            "core.opm.dev/category": "workload"
            "core.opm.dev/type":     "restart"
        }
    }

    appliesTo: [#ContainerUnit]

    #spec: restartPolicy: #RestartPolicySchema
})

#RestartPolicy: close(#ComponentDefinition & {
    #traits: {(#RestartPolicyTrait.metadata.fqn): #RestartPolicyTrait}
})
```

**Usage:**

```cue
worker: #ComponentDefinition & {
    metadata: name: "worker"

    #Container
    #RestartPolicy

    spec: {
        container: {image: "worker:v1"}
        restartPolicy: "OnFailure"  // Only restart on failure
    }
}
```

---

## The appliesTo Field

The `appliesTo` field is the **defining characteristic** of Traits and provides type safety for trait application.

### Purpose

- **Type constraint**: Defines which Units this trait can modify
- **Compile-time validation**: CUE validates compatibility before deployment
- **Self-documentation**: Clear which units a trait works with
- **Prevents misuse**: Can't apply incompatible traits to components

### Syntax

```cue
appliesTo: [...#UnitDefinition]
```

**Must contain:**

- At least one Unit definition reference
- Full CUE references (NOT FQN strings)

### Single Unit Constraint

Most traits apply to a specific unit type:

```cue
#ReplicasTrait: {
    appliesTo: [#ContainerUnit]  // Only works with Container units
    // ...
}
```

### Multiple Unit Constraints

Some traits can apply to multiple unit types:

```cue
#NetworkPolicyTrait: {
    appliesTo: [#ContainerUnit, #PodUnit]  // Works with either
    // ...
}
```

### Why Full References?

**DO:** Use full CUE references

```cue
appliesTo: [#ContainerUnit]  // ✅ Full reference
```

**DON'T:** Use FQN strings

```cue
appliesTo: ["opm.dev/units/workload@v1#Container"]  // ❌ Wrong!
```

**Reasons:**

1. **Type safety**: CUE validates the reference exists
2. **IDE support**: Autocomplete and go-to-definition work
3. **Refactoring**: Changes propagate automatically
4. **Compile-time checking**: Errors caught early

### Validation

When a component includes a trait, CUE validates:

1. **Trait compatibility**: Component must have at least one unit matching `appliesTo`
2. **Field requirements**: All trait spec fields must be provided
3. **No conflicts**: Trait fields don't conflict with unit fields

**Example validation:**

```cue
// This WORKS - Container unit satisfies Replicas trait's appliesTo
api: #ComponentDefinition & {
    #Container  // Unit
    #Replicas   // Trait (appliesTo: [#ContainerUnit])

    spec: {
        container: {...}
        replicas:  3
    }
}

// This FAILS - No Container unit for Replicas trait
config: #ComponentDefinition & {
    #ConfigMap  // ConfigMap unit only
    #Replicas   // ERROR: Replicas requires Container unit!
}
```

### Future: Conditional appliesTo

While not yet implemented, future versions may support conditional constraints:

```cue
// Hypothetical future syntax
appliesTo: [...#UnitDefinition] & {
    metadata: {
        labels: {
            "core.opm.dev/category": "workload"  // Only workload units
        }
    }
}
```

---

## Schema Patterns

Trait schemas follow the same patterns as Unit schemas. See [Unit Definition - Schema Patterns](UNIT_DEFINITION.md#schema-patterns) for comprehensive examples.

### Common Trait Schema Patterns

**Simple constraints:**

```cue
#spec: replicas: int & >=1 & <=100 | *1
#spec: priority: int & >=0 & <=1000
```

**Enums with defaults:**

```cue
#spec: restartPolicy: "Always" | "OnFailure" | "Never" | *"Always"
#spec: pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
```

**Optional nested structures:**

```cue
#spec: autoscaling: {
    enabled?:     bool | *false
    minReplicas?: int & >0 | *1
    maxReplicas?: int & >0 | *10
    targetCPU?:   int & >0 & <=100 | *80
}
```

**Maps:**

```cue
#spec: annotations: [key=string]: string
#spec: tolerations: [name=string]: {
    key:      string
    operator: "Equal" | "Exists"
    effect:   "NoSchedule" | "PreferNoSchedule" | "NoExecute"
}
```

---

## Component Integration

### How Traits Compose

Traits are added to components through the `#traits` map, indexed by FQN:

```cue
#ComponentDefinition: {
    // Map of units by FQN
    #units: [UnitFQN=string]: #UnitDefinition

    // Map of traits by FQN (optional)
    #traits?: [TraitFQN=string]: #TraitDefinition

    // Spec fields automatically merged from units and traits
    spec: {
        // User provides concrete values matching all schemas
    }
}
```

### Using the Helper Pattern

Each trait typically has a helper definition for easy composition:

```cue
// Pattern: #<TraitName>: close(#ComponentDefinition & {#traits: {...}})
#Replicas: close(#ComponentDefinition & {
    #traits: {(#ReplicasTrait.metadata.fqn): #ReplicasTrait}
})

#Expose: close(#ComponentDefinition & {
    #traits: {(#ExposeTrait.metadata.fqn): #ExposeTrait}
})
```

**Usage:**

```cue
myComponent: #ComponentDefinition & {
    metadata: name: "my-app"

    // Mix in units
    #Container
    #Volumes

    // Mix in traits
    #Replicas
    #Expose
    #HealthCheck

    spec: {
        // Unit fields
        container: {...}
        volumes:   {...}

        // Trait fields
        replicas:    3
        expose:      {...}
        healthCheck: {...}
    }
}
```

### Automatic Field Merging

Component automatically merges spec fields from units AND traits:

```cue
#ComponentDefinition: {
    #units: {...}
    #traits?: {...}

    // Internal: merge all unit and trait specs
    _allFields: {
        // Merge unit specs
        for _, unit in #units {
            if unit.#spec != _|_ {
                for k, v in unit.#spec {
                    (k): v
                }
            }
        }
        // Merge trait specs
        if #traits != _|_ {
            for _, trait in #traits {
                if trait.#spec != _|_ {
                    for k, v in trait.#spec {
                        (k): v
                    }
                }
            }
        }
    }

    // User spec must conform to merged schema
    spec: close(_allFields)
}
```

**Result:**

```cue
// With #Container unit + #Replicas trait + #Expose trait:
spec: {
    container: #ContainerSchema  // From Container unit
    replicas:  #ReplicasSchema   // From Replicas trait
    expose:    #ExposeSchema     // From Expose trait
}
```

### appliesTo Validation

When a component includes traits, CUE validates appliesTo constraints:

```cue
// Example validation
#Component: {
    #units: {
        "opm.dev/units/workload@v1#Container": #ContainerUnit
    }
    #traits: {
        "opm.dev/traits/scaling@v1#Replicas": #ReplicasTrait
    }

    // CUE checks:
    // 1. Does #ReplicasTrait.appliesTo include #ContainerUnit? ✅
    // 2. Are all required fields provided in spec? (checked separately)
}
```

If `appliesTo` is not satisfied, CUE will error during evaluation.

---

## Validation Rules

### Definition-Level Validation

1. **Root fields must be exact:**

   ```cue
   apiVersion: "opm.dev/core/v1"  // Must be this exact value
   kind:       "Trait"             // Must be "Trait"
   ```

2. **Metadata fields required:**
   - `metadata.apiVersion` must be present and valid
   - `metadata.name` must be PascalCase, 1-254 characters
   - `metadata.fqn` must be computed, not manually set

3. **appliesTo must be present and non-empty:**

   ```cue
   appliesTo!: [...#UnitDefinition]  // At least one unit required
   ```

4. **#spec must be present:**
   - Must define exactly one field
   - Field name must match `strings.ToCamel(metadata.name)`

5. **FQN must be unique:**
   - No two traits can have same `metadata.fqn`
   - FQN must match regex pattern

### Schema-Level Validation

Same patterns as Units. See [Unit Definition - Schema-Level Validation](UNIT_DEFINITION.md#schema-level-validation).

### Component Integration Validation

1. **appliesTo constraints must be satisfied:**
   - Component must have at least one unit matching trait's `appliesTo`

2. **All trait specs must be satisfiable:**
   - Component spec must provide values for all required trait fields

3. **No field conflicts:**
   - Two traits cannot define the same spec field name
   - Traits and units cannot define the same spec field name
   - CUE will error on field conflicts during unification

4. **FQN uniqueness:**
   - Each trait in `#traits` map must have unique FQN

---

## Trait Categories

Common trait categories and their purposes:

### Scaling Traits

Control workload replica counts and autoscaling:

- **Replicas**: Static replica count
- **Autoscaling**: Horizontal pod autoscaling
- **VerticalScaling**: Vertical pod autoscaling (future)

**Examples:**

```cue
"opm.dev/traits/scaling@v1#Replicas"
"opm.dev/traits/scaling@v1#HPA"
```

### Networking Traits

Control service exposure and traffic routing:

- **Expose**: Service exposure (ClusterIP, NodePort, LoadBalancer)
- **Ingress**: HTTP/HTTPS routing
- **ServiceMesh**: Service mesh integration
- **NetworkPolicy**: Network isolation rules

**Examples:**

```cue
"opm.dev/traits/networking@v1#Expose"
"opm.dev/traits/networking@v1#Ingress"
```

### Health Traits

Configure health checking and monitoring:

- **HealthCheck**: Liveness, readiness, startup probes
- **Monitoring**: Metrics, logging, tracing
- **Alerting**: Alert rules and notification

**Examples:**

```cue
"opm.dev/traits/health@v1#HealthCheck"
"opm.dev/traits/health@v1#Monitoring"
```

### Security Traits

Enforce security policies and configurations:

- **TLS**: TLS/SSL configuration
- **PodSecurity**: Pod security standards
- **RBAC**: Role-based access control
- **Encryption**: Encryption at rest/transit

**Examples:**

```cue
"opm.dev/traits/security@v1#TLS"
"opm.dev/traits/security@v1#PodSecurity"
```

### Restart Traits

Control workload restart behavior:

- **RestartPolicy**: How pods restart on failure
- **BackoffPolicy**: Exponential backoff configuration
- **GracePeriod**: Graceful shutdown configuration

**Examples:**

```cue
"opm.dev/traits/restart@v1#RestartPolicy"
"opm.dev/traits/restart@v1#GracePeriod"
```

### Resource Traits

Manage resource allocation:

- **ResourceLimits**: CPU, memory, storage limits
- **ResourceQuotas**: Namespace-level quotas
- **PriorityClass**: Workload priority

**Examples:**

```cue
"opm.dev/traits/resources@v1#ResourceLimits"
"opm.dev/traits/resources@v1#PriorityClass"
```

---

## Best Practices

### 1. Design Traits for Specific Behaviors

**DO:**

```cue
// ✅ Specific behavior
#ReplicasTrait: {
    metadata: name: "Replicas"
    appliesTo: [#ContainerUnit]
    #spec: replicas: int & >=1 & <=1000
}

#ExposeTrait: {
    metadata: name: "Expose"
    appliesTo: [#ContainerUnit]
    #spec: expose: {...}
}
```

**DON'T:**

```cue
// ❌ Too broad, mixing concerns
#NetworkingTrait: {
    metadata: name: "Networking"
    #spec: networking: {
        replicas:    int      // Not networking!
        expose:      {...}
        ingress:     {...}
        service mesh: {...}
    }
}
```

### 2. Use Descriptive Names

```cue
// ✅ Clear behavior
name: "HealthCheck"
name: "Autoscaling"
name: "RestartPolicy"

// ❌ Unclear
name: "HC"
name: "AS"
name: "Policy"
```

### 3. Provide Sensible Defaults

```cue
#spec: replicas: int & >=1 & <=1000 | *1
#spec: restartPolicy: "Always" | "OnFailure" | "Never" | *"Always"
#spec: pullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
```

### 4. Be Specific with appliesTo

**DO:**

```cue
// ✅ Specific - only applies to Containers
appliesTo: [#ContainerUnit]
```

**DON'T:**

```cue
// ❌ Too broad - could apply to any unit
appliesTo: [...#UnitDefinition]
```

### 5. Document Behavior Clearly

```cue
metadata: {
    description: "Controls the number of replicas for a workload. Higher values provide better availability but consume more resources."
}
```

### 6. Group Related Traits

```cue
// Health traits under same apiVersion
"opm.dev/traits/health@v1"

#HealthCheckTrait:    {...}  // Probes
#MonitoringTrait:     {...}  // Metrics
#AlertingTrait:       {...}  // Alerts
```

### 7. Validate Input Thoroughly

```cue
#spec: replicas: int & >=1 & <=1000  // Reasonable range

#spec: healthCheck: {
    liveness: {
        periodSeconds: int & >0 & <=300  // Max 5 minutes
        timeoutSeconds: int & >0 & <=60  // Max 1 minute
    }
}
```

### 8. Consider Trait Composition

Design traits that work well together:

```cue
// These traits compose well
api: #Component & {
    #Container      // Unit
    #Replicas       // Scaling
    #HealthCheck    // Health
    #Expose         // Networking
    #RestartPolicy  // Restart behavior
}
```

### 9. Version Appropriately

**When to bump major version (@v1 → @v2):**

- Breaking schema changes (removing required fields, changing types)
- Incompatible behavior changes
- Major restructuring

### 10. Provide Helper Definitions

Always create a helper for easy composition:

```cue
// Trait definition
#MyTrait: #TraitDefinition & {...}

// Helper (always provide this!)
#My: close(#ComponentDefinition & {
    #traits: {(#MyTrait.metadata.fqn): #MyTrait}
})
```

---

## Common Pitfalls

### 1. Using FQN Strings in appliesTo

**Wrong:**

```cue
appliesTo: ["opm.dev/units/workload@v1#Container"]  // String! Wrong!
```

**Correct:**

```cue
appliesTo: [#ContainerUnit]  // Full CUE reference
```

### 2. Forgetting appliesTo

**Wrong:**

```cue
#MyTrait: #TraitDefinition & {
    // Missing appliesTo!
}
```

**Correct:**

```cue
#MyTrait: #TraitDefinition & {
    appliesTo: [#ContainerUnit]  // Always include!
}
```

### 3. Empty appliesTo

**Wrong:**

```cue
appliesTo: []  // Empty! Must have at least one unit
```

**Correct:**

```cue
appliesTo: [#ContainerUnit]  // At least one unit
```

### 4. Mixing Units and Traits

**Wrong:**

```cue
#MyUnit: #UnitDefinition & {
    appliesTo: [...]  // Units don't have appliesTo!
}
```

**Correct:**

```cue
// Units don't have appliesTo - that's only for Traits
#MyUnit: #UnitDefinition & {
    // No appliesTo field
}
```

### 5. Too Broad appliesTo

**Discouraged:**

```cue
appliesTo: [...#UnitDefinition]  // Any unit - too broad!
```

**Preferred:**

```cue
appliesTo: [#ContainerUnit]  // Specific unit type
```

### 6. Conflicting Field Names

**Wrong:**

```cue
// Two traits defining same field
#Trait1: {#spec: ports: {...}}
#Trait2: {#spec: ports: {...}}  // Conflict!

api: {
    #Trait1
    #Trait2  // ERROR: ports field conflict
}
```

**Correct:**

```cue
// Use distinct field names
#Trait1: {#spec: containerPorts: {...}}
#Trait2: {#spec: servicePorts: {...}}  // Different field
```

---

## See Also

- [Definition Structure](DEFINITION_STRUCTURE.md) - Complete structure reference
- [Unit Definition](UNIT_DEFINITION.md) - Unit specification (traits modify units)
- [Blueprint Definition](BLUEPRINT_DEFINITION.md) - Composing units and traits
- [Component Definition](COMPONENT_DEFINITION.md) - Using traits in components
- [Quick Reference](QUICK_REFERENCE.md) - One-page cheat sheet
- [FQN Specification](FQN_SPEC.md) - FQN format details

---

**Document Version:** 1.0.0-draft
**Date:** 2025-10-31
