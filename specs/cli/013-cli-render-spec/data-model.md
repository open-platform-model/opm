# Data Model: CLI Render System

## Core Entities

### Pipeline

The central orchestrator.

```go
type Pipeline struct {
    Loader    *Loader
    Provider  *Provider
    Renderer  *Renderer
    Logger    Logger
}
```

### Provider

Represents a loaded OPM provider (e.g., `kubernetes`).

```go
type Provider struct {
    Name         string
    Version      string
    Transformers map[string]*Transformer // Registry of available transformers
}
```

### Transformer

A single transformation unit.

```go
type Transformer struct {
    Name              string
    ID                string // Full CUE path/ID
    RequiredLabels    map[string]string
    RequiredResources []string // Resource types (e.g. "Container")
    RequiredTraits    []string // Trait names (e.g. "Expose")
    
    // The raw CUE value of the transformer (for unification)
    Source cue.Value 
}
```

### Match

Represents the decision to apply a specific transformer to a specific component.

```go
type MatchGroup struct {
    Transformer *Transformer
    Components  []*Component
}

type MatchedMap map[string]*MatchGroup
```

### Component

A wrapper around a component's data.

```go
type Component struct {
    Name      string
    Labels    map[string]string // Effective labels
    Resources []Resource
    Traits    []Trait
    
    Source    cue.Value
}
```

### TransformerContext

Data injected into the transformation.

**Note**: The actual implementation uses CUE's hidden field pattern for metadata injection, giving transformers access to the full module and component metadata structs rather than pre-selected fields. This design is more flexible and idiomatic to CUE.

**CUE Definition**:

```cue
#TransformerContext: close({
    #moduleMetadata:    _ // Injected during rendering (full module metadata)
    #componentMetadata: _ // Injected during rendering (full component metadata)
    name:               string // Release name
    namespace:          string // Target namespace
    
    // Computed label groups
    moduleLabels:     {...} // From #moduleMetadata.labels
    componentLabels:  {...} // From #componentMetadata.labels + instance label
    controllerLabels: {...} // OPM tracking labels (managed-by, name, version, etc.)
    
    // Merged labels (all groups unified)
    labels: {[string]: string}
})
```

**Go Equivalent** (for CLI runtime context construction):

```go
type TransformerContext struct {
    Name      string            `json:"name"`      // Release name
    Namespace string            `json:"namespace"` // Target namespace
    
    // Hidden fields (injected via CUE, not directly accessible in Go)
    ModuleMetadata    map[string]any // Full module metadata struct
    ComponentMetadata map[string]any // Full component metadata struct
    
    // Computed fields (derived in CUE from metadata)
    Labels map[string]string `json:"labels"` // Merged labels
}
```

## Parallel Execution Model

### Worker

A self-contained execution unit.

```go
type Worker struct {
    ID      int
    Context *cue.Context // Isolated context
}

type Job struct {
    TransformerID string
    ComponentData []byte // Marshaled component
    ContextData   []byte // Marshaled context
}

type Result struct {
    Resource *unstructured.Unstructured
    Error    error
}
```
