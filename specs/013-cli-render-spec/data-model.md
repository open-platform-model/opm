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

```go
type TransformerContext struct {
    Name      string            `json:"name"`
    Namespace string            `json:"namespace"`
    Version   string            `json:"version"`
    Provider  string            `json:"provider"`
    Timestamp string            `json:"timestamp"`
    Strict    bool              `json:"strict"`
    Labels    map[string]string `json:"labels"`
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
