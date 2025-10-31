# Unit Definition Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-10-31

## Overview

Units are the fundamental building blocks in OPM that define **what exists** at runtime. A Unit describes a concrete entity that will be provisioned, deployed, or configured in your infrastructure.

### Core Principles

- **Concrete**: Units represent actual runtime entities, not abstract patterns
- **Standalone**: Units are independent and can be used without other units
- **Composable**: Units combine to form complete components
- **Type-safe**: CUE enforces strong typing and validation
- **Platform-agnostic**: Units describe intent, not platform-specific details

### What Units Represent

Units can describe:

- **Workloads**: Containers, processes, functions
- **Storage**: Volumes, persistent storage, ephemeral storage
- **Configuration**: ConfigMaps, secrets, environment variables
- **Networking**: Network policies, service mesh configurations
- **Supporting primitives**: Any runtime entity your platform needs

### Units vs Traits

| Aspect | Units | Traits |
|--------|-------|--------|
| **Purpose** | Define "what exists" | Define "how it behaves" |
| **Independence** | Standalone building blocks | Applied to Units |
| **appliesTo field** | ❌ Not present | ✅ Required |
| **Examples** | Container, Volume, ConfigMap | Replicas, HealthCheck, Expose |

---

## Unit Definition Structure

Every Unit follows this structure:

```cue
#UnitDefinition: close({
    // Root level: OPM core versioning
    apiVersion: #NameType & "opm.dev/core/v1"
    kind:       #NameType & "Unit"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion!:  #NameType                          // Element-specific version path
        name!:        #NameType                          // Unit name (PascalCase)
        fqn:          #FQNType & "\(apiVersion)#\(name)" // Computed FQN
        description?: string                             // Human-readable description
        labels?:      #LabelsAnnotationsType             // For categorization/filtering
        annotations?: #LabelsAnnotationsType             // For behavior hints
    }

    // OpenAPIv3-compatible schema defining the unit's spec structure
    // Field name is auto-derived from metadata.name using camelCase
    #spec!: (strings.ToCamel(metadata.name)): _
})
```

### Hybrid Structure

Units use OPM's two-level structure:

**Root Level (Fixed):**
- `apiVersion: "opm.dev/core/v1"` - Fixed OPM core version
- `kind: "Unit"` - Identifies this as a Unit definition

**Metadata Level (Element-Specific):**
- `metadata.apiVersion` - Element-specific version (e.g., `"opm.dev/units/workload@v1"`)
- `metadata.name` - Unit name (e.g., `"Container"`)
- `metadata.fqn` - Computed as `"\(apiVersion)#\(name)"`

This structure provides:
- **Kubernetes compatibility**: Root fields match K8s manifest structure
- **Independent versioning**: Units can version separately from OPM core
- **Clean exports**: Definitions export as standard K8s-like resources

See [Definition Structure](DEFINITION_STRUCTURE.md) for complete details.

---

## Field Reference

### apiVersion (Root Level)

**Type:** `#NameType`
**Required:** Yes
**Fixed Value:** `"opm.dev/core/v1"`

Identifies this object as an OPM core v1 definition. This field is fixed for all v1 units and represents the OPM core schema version, not the unit's own version.

```cue
apiVersion: "opm.dev/core/v1"  // Always this value for v1 units
```

### kind (Root Level)

**Type:** `#NameType`
**Required:** Yes
**Fixed Value:** `"Unit"`

Identifies this object as a Unit definition (as opposed to Trait, Blueprint, Component, etc.).

```cue
kind: "Unit"  // Always this value for units
```

### metadata.apiVersion (Metadata Level)

**Type:** `#NameType`
**Required:** Yes
**Pattern:** `<domain>/<category>/<subcategory>@v<major>`

The element-specific version path for this unit. This allows the unit to version independently from the OPM core schema.

**Examples:**
```cue
apiVersion: "opm.dev/units/workload@v1"
apiVersion: "opm.dev/units/storage@v1"
apiVersion: "opm.dev/units/config@v1"
apiVersion: "github.com/myorg/units/custom@v1"
```

**Best Practices:**
- Use semantic grouping: `domain/units/category@version`
- Official OPM units use `opm.dev/units/*`
- Third-party units use your domain or GitHub path
- Major version in @v format (e.g., `@v1`, `@v2`)

### metadata.name (Metadata Level)

**Type:** `#NameType`
**Required:** Yes
**Pattern:** PascalCase, starts with uppercase letter

The unit's name, which must be unique within the `metadata.apiVersion` namespace.

**Examples:**
```cue
name: "Container"
name: "Volumes"
name: "ConfigMap"
name: "CustomDatabase"
```

**Naming Rules:**
- Must start with uppercase letter
- Use PascalCase (e.g., `ConfigMap`, not `config_map`)
- Be descriptive, not abbreviated (e.g., `Container`, not `Ctr`)
- Use plural form if unit represents a map of items (e.g., `Volumes`, not `Volume`)

### metadata.fqn (Metadata Level)

**Type:** `#FQNType`
**Required:** Computed (not manually set)
**Pattern:** `<repo-path>@v<major>#<Name>`

The Fully Qualified Name, automatically computed from `metadata.apiVersion` and `metadata.name`.

```cue
metadata: {
    apiVersion: "opm.dev/units/workload@v1"
    name:       "Container"
    fqn:        "\(apiVersion)#\(name)"  // Result: "opm.dev/units/workload@v1#Container"
}
```

**Key Points:**
- **Never manually set** - always use the interpolation pattern
- **Globally unique** - serves as the unit's identifier throughout OPM
- **Used for indexing** - components use FQN as map keys
- **Matches regex**: `^([a-z0-9.-]+(?:/[a-z0-9.-]+)+)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$`

### metadata.description (Metadata Level)

**Type:** `string`
**Required:** No
**Purpose:** Human-readable explanation of the unit

```cue
description: "A container definition for workloads"
description: "Persistent volume definitions for stateful workloads"
```

**Best Practices:**
- Keep concise (1-2 sentences)
- Explain what the unit represents
- Mention key capabilities or constraints
- Use sentence case with period

### metadata.labels (Metadata Level)

**Type:** `#LabelsAnnotationsType` (`[string]: string | int | bool | array`)
**Required:** No
**Purpose:** Categorization and filtering for OPM tooling

Labels are used by the OPM system for:
- **Categorization**: Grouping units by type or purpose
- **Transformer matching**: Selecting appropriate transformers
- **Registry filtering**: Finding units in catalogs
- **Validation**: Enforcing organizational policies

**Examples:**
```cue
labels: {
    "core.opm.dev/category": "workload"
}

labels: {
    "core.opm.dev/category":    "storage"
    "core.opm.dev/persistence": "true"
}

labels: {
    "myorg.com/compliance": "pci-dss"
    "myorg.com/team":       "platform"
}
```

**Recommended Labels:**
- `core.opm.dev/category` - Unit category (workload, storage, config, network)
- `core.opm.dev/type` - Specific type within category
- Organization-specific labels with your domain prefix

### metadata.annotations (Metadata Level)

**Type:** `#LabelsAnnotationsType`
**Required:** No
**Purpose:** Additional metadata NOT used for selection/matching

Annotations provide hints to providers/transformers but are not used for matching logic.

**Examples:**
```cue
annotations: {
    "opm.dev/documentation": "https://opm.dev/docs/units/container"
    "opm.dev/source":        "official"
}

annotations: {
    "myorg.com/owner":        "platform-team"
    "myorg.com/review-date":  "2025-12-31"
}
```

**Typical Uses:**
- Documentation URLs
- Source information
- Ownership metadata
- Review/maintenance schedules
- Provider-specific hints (non-matching)

### #spec (Specification Schema)

**Type:** CUE schema
**Required:** Yes
**Purpose:** OpenAPIv3-compatible schema defining the unit's configuration structure

The `#spec` field defines what configuration users must provide when using this unit in a component.

**Key Characteristics:**
- **Auto-named**: Field name is `strings.ToCamel(metadata.name)`
  - `"Container"` → `container: {...}`
  - `"Volumes"` → `volumes: {...}`
  - `"ConfigMap"` → `configMap: {...}`
- **Uses # prefix**: Allows incomplete/template values (inconcrete fields)
- **OpenAPIv3-compatible**: Can be converted to OpenAPI schemas
- **Arbitrary structure**: Can be any valid CUE type (struct, map, list, constraint)

**Pattern:**
```cue
// For "Container" unit:
#spec: container: #ContainerSchema

// For "Volumes" unit (map of volumes):
#spec: volumes: [volumeName=string]: #VolumeSchema

// For "Replicas" (simple constraint):
#spec: replicas: int & >=1 & <=1000
```

The schema is typically defined separately and then referenced:

```cue
// Define schema
#ContainerSchema: close({
    name!:  string
    image!: string
    ports?: [...]
})

// Use in unit definition
#ContainerUnit: #UnitDefinition & {
    #spec: container: #ContainerSchema
}
```

---

## Complete Examples

### Example 1: Container Unit (Single Object Schema)

```cue
// Schema definition
#ContainerSchema: close({
    name!:           string
    image!:          string
    imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
    ports?: [portName=string]: {
        name:          string
        containerPort: int & >0 & <65536
        protocol:      "TCP" | "UDP" | *"TCP"
    }
    env?: [string]: {
        name:  string
        value: string
    }
    resources?: {
        limits?: {
            cpu?:    string
            memory?: string
        }
        requests?: {
            cpu?:    string
            memory?: string
        }
    }
    volumeMounts?: [string]: {
        mountPath!: string
        subPath?:   string
        readOnly?:  bool | *false
    }
})

// Unit definition
#ContainerUnit: close(#UnitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Unit"

    metadata: {
        apiVersion:  "opm.dev/units/workload@v1"
        name:        "Container"
        fqn:         "opm.dev/units/workload@v1#Container"
        description: "A container definition for workloads"
        labels: {
            "core.opm.dev/category": "workload"
        }
    }

    // Creates field: container: #ContainerSchema
    #spec: container: #ContainerSchema
})

// Helper for component composition
#Container: close(#ComponentDefinition & {
    #units: {(#ContainerUnit.metadata.fqn): #ContainerUnit}
})
```

**Usage in Component:**

```cue
webServer: #ComponentDefinition & {
    metadata: name: "web-server"

    #Container  // Mix in Container unit

    spec: {
        container: {
            name:  "nginx"
            image: "nginx:latest"
            ports: {
                http: {
                    name:          "http"
                    containerPort: 80
                }
            }
            resources: {
                requests: {
                    cpu:    "100m"
                    memory: "128Mi"
                }
                limits: {
                    cpu:    "500m"
                    memory: "512Mi"
                }
            }
        }
    }
}
```

### Example 2: Volumes Unit (Map-Based Schema)

```cue
// Schema definition for a single volume
#VolumeSchema: close({
    name!:     string
    capacity!: string & =~"^[0-9]+[GT]i$"
    accessModes!: ["ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany", ...]
    storageClassName?: string
})

// Unit definition
#VolumesUnit: close(#UnitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Unit"

    metadata: {
        apiVersion:  "opm.dev/units/storage@v1"
        name:        "Volumes"
        fqn:         "opm.dev/units/storage@v1#Volumes"
        description: "Volume definitions for stateful workloads"
        labels: {
            "core.opm.dev/category":    "storage"
            "core.opm.dev/persistence": "true"
        }
    }

    // Creates map field: volumes: [volumeName=string]: #VolumeSchema
    // Note: Default name to volumeName if not specified
    #spec: volumes: [volumeName=string]: #VolumeSchema & {name: string | *volumeName}
})

// Helper for component composition
#Volumes: close(#ComponentDefinition & {
    #units: {(#VolumesUnit.metadata.fqn): #VolumesUnit}
})
```

**Usage in Component:**

```cue
database: #ComponentDefinition & {
    metadata: name: "database"

    #Container
    #Volumes  // Mix in Volumes unit

    spec: {
        container: {
            name:  "postgres"
            image: "postgres:15"
        }
        volumes: {
            dbData: {
                name:             "dbData"
                capacity:         "100Gi"
                accessModes:      ["ReadWriteOnce"]
                storageClassName: "fast-ssd"
            }
            dbBackup: {
                capacity:    "50Gi"
                accessModes: ["ReadWriteOnce"]
            }
        }
    }
}
```

### Example 3: ConfigMap Unit

```cue
#ConfigMapSchema: close({
    data!: [key=string]: string
    binaryData?: [key=string]: bytes
})

#ConfigMapUnit: close(#UnitDefinition & {
    apiVersion: "opm.dev/core/v1"
    kind:       "Unit"

    metadata: {
        apiVersion:  "opm.dev/units/config@v1"
        name:        "ConfigMap"
        fqn:         "opm.dev/units/config@v1#ConfigMap"
        description: "Configuration data for workloads"
        labels: {
            "core.opm.dev/category": "config"
        }
    }

    #spec: configMap: #ConfigMapSchema
})

#ConfigMap: close(#ComponentDefinition & {
    #units: {(#ConfigMapUnit.metadata.fqn): #ConfigMapUnit}
})
```

**Usage:**

```cue
api: #ComponentDefinition & {
    metadata: name: "api"

    #Container
    #ConfigMap

    spec: {
        container: {
            name:  "api"
            image: "api:v1"
        }
        configMap: {
            data: {
                "app.conf":     "server.port=8080"
                "database.url": "postgresql://db:5432/myapp"
            }
        }
    }
}
```

---

## Naming Conventions

### Singular vs Plural Names

Use **plural form** when the unit represents a map or collection of items:

**Use Plural (Map/Collection):**

```cue
// ✅ Plural - represents multiple volumes
#VolumesUnit: {
    metadata: name: "Volumes"
    #spec: volumes: [volumeName=string]: #VolumeSchema
}

// ✅ Plural - represents multiple secrets
#SecretsUnit: {
    metadata: name: "Secrets"
    #spec: secrets: [secretName=string]: #SecretSchema
}
```

**Use Singular (Single Object):**

```cue
// ✅ Singular - represents one container
#ContainerUnit: {
    metadata: name: "Container"
    #spec: container: #ContainerSchema
}

// ✅ Singular - represents one config map
#ConfigMapUnit: {
    metadata: name: "ConfigMap"
    #spec: configMap: #ConfigMapSchema
}
```

### PascalCase Requirement

Always use PascalCase for unit names:

```cue
// ✅ Correct
name: "Container"
name: "ConfigMap"
name: "StatefulStorage"

// ❌ Wrong
name: "container"
name: "config_map"
name: "stateful-storage"
```

The camelCase field name is automatically generated:

- `"Container"` → `container: {...}`
- `"ConfigMap"` → `configMap: {...}`
- `"StatefulStorage"` → `statefulStorage: {...}`

---

## Schema Patterns

### Required vs Optional Fields

```cue
#Schema: {
    // Required field (! suffix)
    name!: string
    image!: string

    // Optional field (? suffix)
    description?: string
    tags?: [...string]
}
```

### Default Values

```cue
#Schema: {
    // Default with | operator
    imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"

    // Default for boolean
    enabled: bool | *true
    readOnly?: bool | *false

    // Default for numbers
    replicas: int & >=1 & <=100 | *1
}
```

### Constraints

```cue
#Schema: {
    // Integer constraints
    port: int & >0 & <65536
    replicas: int & >=1 & <=1000

    // String constraints
    name: string & =~"^[a-z0-9-]+$"
    capacity: string & =~"^[0-9]+[GT]i$"

    // Enum constraints
    protocol: "TCP" | "UDP" | "SCTP"

    // Length constraints
    description: string & strings.MinRunes(1) & strings.MaxRunes(256)
}
```

### Nested Structures

```cue
#Schema: {
    container: {
        name!:  string
        image!: string

        // Nested optional struct
        resources?: {
            limits?: {
                cpu?:    string
                memory?: string
            }
            requests?: {
                cpu?:    string
                memory?: string
            }
        }
    }
}
```

### Maps with Typed Values

```cue
#Schema: {
    // Map: [key=string]: ValueType
    ports?: [portName=string]: {
        containerPort: int & >0 & <65536
        protocol:      "TCP" | "UDP" | *"TCP"
    }

    // Map with default key value
    volumes?: [volumeName=string]: {
        name: string | *volumeName  // Defaults to key if not specified
        size: string
    }
}
```

### Lists

```cue
#Schema: {
    // Simple list
    tags?: [...string]

    // List of structs
    ports?: [...{
        containerPort: int
        protocol:      string
    }]

    // List with constraints
    accessModes!: ["ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany", ...] & list.MinItems(1)
}
```

---

## Component Integration

### How Units Compose

Units are added to components through the `#units` map, indexed by FQN:

```cue
#ComponentDefinition: {
    // Map of units by FQN
    #units: [UnitFQN=string]: #UnitDefinition

    // Spec fields automatically merged from all units
    spec: {
        // User provides concrete values matching all unit schemas
    }
}
```

### Using the Helper Pattern

Each unit typically has a helper definition for easy composition:

```cue
// Pattern: #<UnitName>: close(#ComponentDefinition & {#units: {...}})
#Container: close(#ComponentDefinition & {
    #units: {(#ContainerUnit.metadata.fqn): #ContainerUnit}
})

#Volumes: close(#ComponentDefinition & {
    #units: {(#VolumesUnit.metadata.fqn): #VolumesUnit}
})
```

**Usage:**

```cue
myComponent: #ComponentDefinition & {
    metadata: name: "my-app"

    // Mix in multiple units
    #Container
    #Volumes
    #ConfigMap

    spec: {
        // Fields from Container unit
        container: {...}

        // Fields from Volumes unit
        volumes: {...}

        // Fields from ConfigMap unit
        configMap: {...}
    }
}
```

### FQN-Based Indexing

Units are indexed by their FQN, which ensures:
- **Uniqueness**: No two units can have the same FQN
- **Explicit references**: Clear which unit provides which fields
- **Transformer matching**: Transformers can require specific units by FQN

```cue
#units: {
    "opm.dev/units/workload@v1#Container": #ContainerUnit
    "opm.dev/units/storage@v1#Volumes":    #VolumesUnit
}
```

### Automatic Field Merging

Component automatically merges spec fields from all units:

```cue
#ComponentDefinition: {
    #units: {...}

    // Internal: merge all unit specs
    _allFields: {
        for _, unit in #units {
            if unit.#spec != _|_ {
                for k, v in unit.#spec {
                    (k): v
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
// With #Container and #Volumes:
spec: {
    container: #ContainerSchema  // From Container unit
    volumes: #VolumesSchema      // From Volumes unit
}
```

### Validation

CUE validates that:
1. All required unit fields are provided in `spec`
2. Field values match unit schema constraints
3. No conflicting field names between units
4. All FQNs are unique within component

---

## Validation Rules

### Definition-Level Validation

1. **Root fields must be exact:**
   ```cue
   apiVersion: "opm.dev/core/v1"  // Must be this exact value
   kind:       "Unit"              // Must be "Unit"
   ```

2. **Metadata fields required:**
   - `metadata.apiVersion` must be present and valid
   - `metadata.name` must be PascalCase, 1-254 characters
   - `metadata.fqn` must be computed, not manually set

3. **FQN must be unique:**
   - No two units can have same `metadata.fqn`
   - FQN must match regex pattern

4. **#spec must be present:**
   - Must define exactly one field
   - Field name must match `strings.ToCamel(metadata.name)`

5. **No appliesTo field:**
   - Units are independent, cannot have `appliesTo`
   - Only Traits have `appliesTo`

### Schema-Level Validation

1. **Use close() for strict schemas:**
   ```cue
   #Schema: close({
       name!: string
       // Only these fields allowed
   })
   ```

2. **Mark required fields with !:**
   ```cue
   image!: string    // Required
   tags?: [...string]  // Optional
   ```

3. **Provide sensible defaults:**
   ```cue
   enabled: bool | *true
   protocol: "TCP" | "UDP" | *"TCP"
   ```

4. **Use appropriate constraints:**
   ```cue
   port: int & >0 & <65536
   name: string & =~"^[a-z0-9-]+$"
   ```

### Component Integration Validation

1. **All unit specs must be satisfiable:**
   - Component spec must provide values for all required unit fields

2. **No field conflicts:**
   - Two units cannot define the same spec field name
   - CUE will error on field conflicts during unification

3. **FQN uniqueness:**
   - Each unit in `#units` map must have unique FQN

4. **Helper consistency:**
   - Helper definition must correctly reference unit by FQN

---

## Best Practices

### 1. Design Units for Reusability

**DO:**
```cue
// ✅ Generic, reusable
#ContainerUnit: {
    metadata: name: "Container"
    #spec: container: {
        image!: string
        ports?: [...]
        // Generic container fields
    }
}
```

**DON'T:**
```cue
// ❌ Too specific, not reusable
#NginxContainerUnit: {
    metadata: name: "NginxContainer"
    #spec: nginxContainer: {
        image: "nginx:latest"  // Hardcoded!
        // Nginx-specific only
    }
}
```

### 2. Use Clear, Descriptive Names

```cue
// ✅ Clear
name: "Container"
name: "PersistentVolume"
name: "NetworkPolicy"

// ❌ Unclear
name: "Ctr"
name: "PV"
name: "NetPol"
```

### 3. Provide Comprehensive Labels

```cue
// ✅ Well-labeled
metadata: {
    labels: {
        "core.opm.dev/category":    "workload"
        "core.opm.dev/type":        "container"
        "core.opm.dev/stateful":    "false"
        "myorg.com/compliance":     "pci-dss"
    }
}
```

### 4. Document Complex Schemas

```cue
#ContainerSchema: {
    // Required: Container image to run
    image!: string

    // Optional: Resource limits and requests
    // If not specified, platform defaults apply
    resources?: {
        limits?: {...}
        requests?: {...}
    }
}
```

### 5. Use Sensible Defaults

```cue
#Schema: {
    imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
    restartPolicy:   "Always" | "OnFailure" | "Never" | *"Always"
    readOnly:        bool | *false
}
```

### 6. Validate Input Constraints

```cue
#Schema: {
    // Constrain to valid range
    replicas: int & >=0 & <=1000

    // Validate format
    capacity: string & =~"^[0-9]+[GT]i$"

    // Enforce naming conventions
    name: string & =~"^[a-z0-9-]+$"
}
```

### 7. Group Related Units

```cue
// Storage units under same apiVersion
"opm.dev/units/storage@v1"

#VolumesUnit:            {...}  // Volumes
#PersistentVolumeUnit:   {...}  // PersistentVolume
#EphemeralVolumeUnit:    {...}  // EphemeralVolume
```

### 8. Version Appropriately

**When to bump major version (@v1 → @v2):**
- Breaking schema changes (removing required fields, changing types)
- Incompatible behavior changes
- Major restructuring

**When to bump minor/patch (in full semver):**
- Adding optional fields
- Bug fixes
- Documentation improvements

### 9. Test With Real Components

Always test units in actual component definitions:

```cue
// Test unit in component
testComponent: #ComponentDefinition & {
    #Container
    spec: {
        container: {
            image: "test:latest"
            // Verify all required fields work
        }
    }
}
```

### 10. Provide Helper Definitions

Always create a helper for easy composition:

```cue
// Unit definition
#MyUnit: #UnitDefinition & {...}

// Helper (always provide this!)
#My: close(#ComponentDefinition & {
    #units: {(#MyUnit.metadata.fqn): #MyUnit}
})
```

---

## Common Pitfalls

### 1. Forgetting metadata.apiVersion

**Wrong:**
```cue
metadata: {
    name: "Container"
    fqn:  "opm.dev/units/workload@v1#Container"
}
```

**Correct:**
```cue
metadata: {
    apiVersion: "opm.dev/units/workload@v1"  // Don't forget!
    name:       "Container"
    fqn:        "opm.dev/units/workload@v1#Container"
}
```

### 2. Manually Setting FQN

**Wrong:**
```cue
metadata: {
    apiVersion: "opm.dev/units/workload@v1"
    name:       "Container"
    fqn:        "opm.dev/units/workload@v1#ContainerUnit"  // Manually set, wrong!
}
```

**Correct:**
```cue
metadata: {
    apiVersion: "opm.dev/units/workload@v1"
    name:       "Container"
    fqn:        "\(apiVersion)#\(name)"  // Computed, always correct
}
```

### 3. Wrong Spec Field Name

**Wrong:**
```cue
#ContainerUnit: {
    metadata: name: "Container"
    #spec: myContainer: {...}  // Wrong! Should be camelCase of name
}
```

**Correct:**
```cue
#ContainerUnit: {
    metadata: name: "Container"
    #spec: container: {...}  // Correct! strings.ToCamel("Container") = "container"
}
```

### 4. Adding appliesTo to Units

**Wrong:**
```cue
#ContainerUnit: #UnitDefinition & {
    appliesTo: [...]  // Units don't have appliesTo!
}
```

**Correct:**
```cue
// Units don't have appliesTo - they're independent
#ContainerUnit: #UnitDefinition & {
    // No appliesTo field
}
```

### 5. Forgetting close()

**Wrong:**
```cue
#ContainerUnit: #UnitDefinition & {  // Missing close()
    metadata: {...}
}
```

**Correct:**
```cue
#ContainerUnit: close(#UnitDefinition & {  // Use close()
    metadata: {...}
})
```

### 6. Incorrect Plural/Singular Usage

**Wrong:**
```cue
// Using singular for a map
#VolumeUnit: {
    metadata: name: "Volume"
    #spec: volume: [volumeName=string]: {...}  // Represents multiple, should be plural!
}
```

**Correct:**
```cue
#VolumesUnit: {
    metadata: name: "Volumes"  // Plural for map
    #spec: volumes: [volumeName=string]: {...}
}
```

---

## See Also

- [Definition Structure](DEFINITION_STRUCTURE.md) - Complete structure reference
- [Trait Definition](TRAIT_DEFINITION.md) - Trait specification (units + behavior)
- [Blueprint Definition](BLUEPRINT_DEFINITION.md) - Composing units and traits
- [Component Definition](COMPONENT_DEFINITION.md) - Using units in components
- [Quick Reference](QUICK_REFERENCE.md) - One-page cheat sheet
- [FQN Specification](FQN_SPEC.md) - FQN format details

---

**Document Version:** 1.0.0-draft
**Date:** 2025-10-31
