# Research: Timoni Values System Analysis

**Date**: 2026-01-28  
**Analyzed**: Timoni codebase at `/var/home/emil/Dev/open-platform-model/timoni/`

## Overview

This document captures the analysis of Timoni's values and configuration system to inform OPM's platform runtime design. Timoni implements a sophisticated tiered values system with overlay-based merging that aligns well with OPM's needs.

## Timoni Architecture

### Module Structure

```text
module/
├── values.cue           # User-supplied values (placeholder, concrete values)
├── timoni.cue           # Main workflow: schema binding + instance definition
├── templates/
│   └── config.cue       # #Config schema definition (defaults + constraints)
└── timoni.ignore        # Files to exclude from bundle
```

### Key Files

**templates/config.cue** - Schema definition with defaults:

```cue
#Config: {
  metadata: {
    name:      *"test" | string      // Default with constraint
    namespace: *"default" | string
  }
  hostname:      *"default.internal" | string
  moduleVersion: string              // Required, no default
}
```

**values.cue** - Placeholder for user-supplied concrete values:

```cue
package main
values: {
  // User values go here
}
```

**timoni.cue** - Binds values to schema and defines instance:

```cue
values: templates.#Config   // Schema constraint on values

timoni: {
  apiVersion: "v1alpha1"
  instance: templates.#Instance & {
    config: values                          // Values flow into config
    config: metadata: {
      name:      string @tag(name)          // Runtime injection via tags
      namespace: string @tag(namespace)
    }
  }
  apply: all: [for obj in instance.objects {obj}]
}
```

## Values Layering System

### Tiered Override System

**Layer Order (lowest to highest priority):**

1. **Module defaults** - In `templates/config.cue` (e.g., `*"default" | string`)
2. **Base values** - Module's `values.cue` file
3. **Overlay values** - Applied via `-f` flags in order
4. **Runtime values** - Injected via `@timoni()` attributes or CUE tags

### Merge Algorithm

Located in `internal/engine/values_builder.go`:

```go
func MergeValues(overlays [][]byte, base string) (cue.Value, error) {
    // 1. Load base values file
    baseVal := ExtractValueFromFile(ctx, base, "values")
    
    // 2. Apply overlays in order (later overlays win)
    for _, overlay := range overlays {
        overlayVal := ExtractValueFromBytes(ctx, overlay, "values")
        baseVal = MergeValue(overlayVal, baseVal)  // Deep merge
    }
    return baseVal, nil
}
```

**Deep Merge Implementation (utils.go):**

| Type | Merge Behavior |
|------|----------------|
| **Structs** | Recursive merge - overlay adds/overrides fields, base keeps unspecified fields |
| **Lists** | Element-by-element merge (not append) |
| **Scalars** | Overlay completely replaces base |

```go
func mergeValue(overlay, base cue.Value) (cue.Value, bool) {
    switch base.IncompleteKind() {
    case cue.StructKind:
        return mergeStruct(overlay, base)  // Recursive struct merge
    case cue.ListKind:
        return mergeList(overlay, base)    // Element-by-element list merge
    }
    return overlay, true  // Scalars: overlay wins
}
```

### Example from Testdata

**base.cue:**

```cue
values: {
  resources: {
    requests: { cpu: "100m", memory: "128Mi" }
    limits: memory: requests.memory
  }
  securityContext: {
    allowPrivilegeEscalation: false
    capabilities: { drop: ["ALL"], add: ["NET_BIND_SERVICE", "SYS_TIME"] }
  }
}
```

**overlay-1.cue:**

```cue
values: {
  resources: limits: { cpu: "1000m", memory: "1Gi" }
  securityContext: {
    readOnlyRootFilesystem: false
    capabilities: add: ["NET_BIND_SERVICE"]  // List replaced entirely
  }
}
```

**Merged Result:**

```cue
values: {
  resources: {
    requests: { cpu: "100m", memory: "128Mi" }  // Kept from base
    limits: { cpu: "1000m", memory: "1Gi" }      // Merged: overlay wins
  }
  securityContext: {
    allowPrivilegeEscalation: false             // Kept from base
    readOnlyRootFilesystem: false               // Added by overlay
    capabilities: add: ["NET_BIND_SERVICE"]     // Replaced by overlay
  }
}
```

## Runtime Value Injection

Timoni supports two injection mechanisms:

### 1. Build-time Tags (`@tag`)

```cue
config: {
  moduleVersion: string @tag(mv, var=moduleVersion)
  kubeVersion:   string @tag(kv, var=kubeVersion)
}
```

Injected via CLI flags: `timoni build -t mv=1.0.0 -t kv=1.28.0`

### 2. Runtime Attributes (`@timoni`)

```cue
myField: string @timoni(runtime:string:MY_VAR)
```

Values sourced from cluster resources at runtime.

## Multi-format Support

Located in `internal/engine/values_builder.go`:

```go
func convertToCue(paths []string) ([][]byte, error) {
    switch ext {
    case ".cue": return bs  // Direct
    case ".json": return json.Extract(path, bs)
    case ".yaml": return yaml.Extract(path, bs)
    }
}
```

Timoni accepts CUE, YAML, and JSON value files, converting all to CUE internally for unified processing.

## Validation Points

1. **At module build** - `timoni.cue` binds `values: templates.#Config`
2. **After merge** - `builder.Build()` validates via `instance.Validate(cue.Concrete(true), cue.Final())`
3. **Bundle schema** - Separate CUE schema injected at build time

## CUE Path Selectors

Timoni defines well-known paths as API:

```go
const (
  ValuesSelector       = "values"                   // Module values
  ConfigValuesSelector = "timoni.instance.config"   // Instance config
  BundleValuesSelector = "values"                   // Bundle instance values
  RuntimeValuesSelector = "runtime.values"          // Runtime-injected values
)
```

This enables tooling to extract specific subtrees without full AST manipulation.

## Key Patterns for OPM

### Patterns to Adopt

| Pattern | Rationale | OPM Application |
|---------|-----------|-----------------|
| **Schema/Values Separation** | Clear contract between constraints and data | Already adopted in 001-spec |
| **Overlay System** | Simple, predictable merging | Use for tiered values (Author → Platform → User) |
| **Multi-format Support** | Better UX for YAML/Helm users | Accept CUE, YAML, JSON values |
| **Deep Merge Semantics** | Intuitive for nested configs | Adopt for Platform Operator overlays |
| **Well-known Paths** | Enables consistent tooling | Define `config`, `values`, `catalog.values` paths |

### Patterns to Adapt

| Pattern | Timoni Approach | OPM Adaptation |
|---------|-----------------|----------------|
| **Locking** | Not built-in | Use CUE unification: concrete values are immutable, `*` allows override |
| **Conflict Handling** | Last overlay wins silently | Produce clear error with provenance when locked value conflicts |
| **Runtime Injection** | `@tag` and `@timoni` | Defer to controller spec, not needed for initial catalog |

### Patterns to Skip

| Pattern | Reason |
|---------|--------|
| **`@timoni()` attributes** | Runtime controller concern, not needed for catalog spec |
| **List merging** | CUE list unification is sufficient for OPM use cases |

## Design Decisions

### Decision 1: Overlay System Over Unification-Only

**Choice**: Adopt Timoni-style overlay system with deep merge semantics.

**Rationale**:

- More intuitive for operators coming from Helm/Kustomize
- Predictable behavior: later layer wins
- Allows gradual refinement of values across tiers

**Implementation**: CLI merges overlay files in order, validates result against schema.

### Decision 2: Implicit Locking via Concrete Values

**Choice**: Platform Operator concrete values (no `*`) are automatically locked.

**Rationale**:

- No special syntax required
- Natural CUE semantics: concrete values cannot be overridden
- Platform Operator uses `*` when they want to allow overrides

**Error Messages**: Must clearly indicate which tier locked the value.

### Decision 3: Multi-format Input

**Choice**: Accept CUE, YAML, JSON value files.

**Rationale**:

- Reduces migration friction from Helm/Kustomize
- YAML is more familiar to many operators
- Conversion to CUE is straightforward (Timoni proves this)

**Implementation**: CLI converts YAML/JSON to CUE before merging.

### Decision 4: Module Catalog as Central Registry

**Choice**: End Users can only deploy modules from `#ModuleCatalog`.

**Rationale**:

- Gives Platform Operators control over approved modules
- Natural place to apply platform overlays
- Aligns with enterprise governance requirements

**Implementation**: `#ModuleRelease` references catalog entry by name.

## References

### Timoni Source Files Analyzed

- `internal/engine/values_builder.go` - Merge algorithm
- `internal/engine/values_builder_test.go` - Test cases
- `internal/engine/utils.go` - Deep merge implementation
- `internal/engine/testdata/module/` - Module structure
- `internal/engine/testdata/values/` - Overlay examples

### Timoni Documentation

- [Timoni Modules](https://timoni.sh/modules/)
- [Timoni Values](https://timoni.sh/values/)
- [Timoni Bundle](https://timoni.sh/bundle/)

## Conclusion

Timoni's values system provides a proven foundation for OPM's tiered values approach. The overlay system with deep merge semantics is intuitive and powerful. By adapting Timoni's patterns with OPM's CUE-first philosophy and adding explicit locking semantics, we can create a values system that balances flexibility with governance.
