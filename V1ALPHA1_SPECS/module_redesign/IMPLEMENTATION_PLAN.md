# Module Flattening Implementation Plan

## Overview

This document details the implementation of a Go library that transforms OPM modules through three distinct layers:

1. **ModuleDefinition** - Authoring layer with Blueprints (created by developers and/or platform teams)
2. **Module** (IR) - Compiled/optimized form with Blueprints expanded to Units + Traits
3. **ModuleRelease** - Module + concrete values for deployment

## Core Concept

The key insight: **Blueprints are authoring sugar**. Transformers only care about Units and Traits, so we can "compile away" Blueprints into their constituent parts while preserving validation, constraints, and metadata.

## Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ ModuleDefinition                                            │
│ - Rich Blueprints (#StatelessWorkload, #SimpleDatabase)    │
│ - High-level abstractions                                   │
│ - Created by developers and/or platform teams               │
│ - Values are constraints only (no defaults)                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ FLATTEN (Go library)
                            │ - Expand Blueprints → Units + Traits
                            │ - Inline referenced schemas
                            │ - Preserve validation & metadata
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Module (IR / Compiled Form)                                 │
│ - Blueprints expanded to Units + Traits                     │
│ - All references resolved & inlined                         │
│ - Constraints preserved                                     │
│ - CUE imports still allowed (memory pointers)               │
│ - Provenance metadata attached                              │
│ - Deterministic ordering                                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ BIND (User provides values)
                            │ - Add concrete values
                            │ - Close all optional fields
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ ModuleRelease (Deployment Artifact)                         │
│ - Module + concrete values                                  │
│ - Everything closed & concrete                              │
│ - Ready for transformer execution                           │
│ - Auditable & diffable                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Concrete Example: Blog Application

### 1. ModuleDefinition (What Developers Write)

```cue
package blog

import (
    opm "opm.dev/core@v1"
    blueprints "opm.dev/blueprints@v1"
)

blogApp: opm.#ModuleDefinition & {
    #metadata: {
        name:    "blog"
        version: "1.0.0"
        labels: {
            "app.name": "blog"
            team:       "content"
        }
    }

    components: {
        // Frontend: Uses composite Blueprint
        frontend: {
            #metadata: {
                name: "frontend"
                labels: {
                    component: "frontend"
                    tier:      "web"
                }
            }

            // HIGH-LEVEL BLUEPRINT
            blueprints.#StatelessWorkload

            statelessWorkload: {
                container: {
                    name:  "blog-frontend"
                    image: values.frontend.image
                    ports: {
                        http: {
                            targetPort: 3000
                            protocol:   "TCP"
                        }
                    }
                    env: {
                        DATABASE_URL: {
                            name:  "DATABASE_URL"
                            value: "postgresql://postgres:5432/blog"
                        }
                    }
                }
                replicas: {
                    count: values.frontend.replicas
                }
                healthCheck: {
                    liveness: {
                        httpGet: {
                            path: "/health"
                            port: 3000
                        }
                    }
                }
            }
        }

        // Database: Uses composite Blueprint
        database: {
            #metadata: {
                name: "database"
                labels: {
                    component: "database"
                    tier:      "data"
                }
            }

            // HIGH-LEVEL BLUEPRINT
            blueprints.#SimpleDatabase

            simpleDatabase: {
                engine:   "postgres"
                version:  "15"
                dbName:   "blog"
                username: "admin"
                password: "changeme"
                persistence: {
                    enabled: true
                    size:    values.database.storageSize
                }
            }
        }
    }

    // Value constraints (no defaults)
    values: {
        frontend: {
            image!:    string
            replicas!: int
        }
        database: {
            storageSize!: string
        }
    }
}
```

**Key Characteristics:**
- Uses `#StatelessWorkload` composite (which contains Container, Replicas, HealthCheck, etc.)
- Uses `#SimpleDatabase` composite (which contains StatefulWorkload, Volume)
- References values via `values.frontend.image`
- Composites hide complexity from developer

---

### 2. Module (IR - What Gets Generated)

```cue
package blog

import (
    opm "github.com/open-platform-model/core"
)

// NOTE: This is generated by the Go flattening library
blogAppModule: opm.#Module & {
    #metadata: {
        name:    "blog"
        version: "1.0.0"
        labels: {
            "app.name": "blog"
            team:       "content"
        }
        annotations: {
            "opm.dev/flattened":     "true"
            "opm.dev/flattener":     "opm-flatten@v0.1.0"
            "opm.dev/source-hash":   "sha256:abc123..."
            "opm.dev/flattened-at":  "2025-10-28T10:30:00Z"
        }
    }

    components: {
        // Frontend: Flattened to Units + Traits
        frontend: {
            #metadata: {
                name: "frontend"
                labels: {
                    component:                    "frontend"
                    tier:                         "web"
                    "core.opm.dev/category":      "workload"
                    "core.opm.dev/workload-type": "stateless"
                }
                annotations: {
                    // Provenance tracking
                    "opm.dev/origin-blueprint": "opm.dev/blueprints/workload@v1#StatelessWorkload"
                    "opm.dev/composed-of": """
                        opm.dev/units/workload@v1#Container,
                        opm.dev/traits/scaling@v1#Replicas,
                        opm.dev/traits/health@v1#HealthCheck
                        """
                }
            }

            // ONLY UNITS AND TRAITS - NO BLUEPRINTS
            #units: {
                "opm.dev/units/workload@v1#Container": {
                    name:        "Container"
                    kind:        "Unit"
                    #apiVersion: "opm.dev/units/workload@v1"
                    target: ["component"]
                    // Schema is INLINED (not just referenced)
                    schema: {
                        name!:  string
                        image!: string
                        imagePullPolicy: "Always" | "IfNotPresent" | "Never" | *"IfNotPresent"
                        ports?: [portName=string]: {
                            name:        string
                            targetPort!: int
                            protocol:    "TCP" | "UDP" | "SCTP" | *"TCP"
                        }
                        env?: [string]: {
                            name!:  string
                            value!: string
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
                            name!:      string
                            mountPath!: string
                            readOnly?:  bool
                        }
                    }
                    description: "A container definition for workloads"
                    labels: {
                        "core.opm.dev/category": "workload"
                    }
                    #fullyQualifiedName: "opm.dev/units/workload@v1#Container"
                    _provenance: {
                        sourceBlueprint: "opm.dev/blueprints/workload@v1#StatelessWorkload"
                        unitHash:        "sha256:def456..."
                    }
                }
            }

            #traits: {
                "opm.dev/traits/scaling@v1#Replicas": {
                    name:        "Replicas"
                    kind:        "Trait"
                    #apiVersion: "opm.dev/traits/scaling@v1"
                    target: ["component"]
                    schema: {
                        count: int | *1
                    }
                    parentUnits: ["opm.dev/units/workload@v1#Container"]
                    description: "Number of desired replicas"
                    labels: {
                        "core.opm.dev/category": "workload"
                    }
                    #fullyQualifiedName: "opm.dev/traits/scaling@v1#Replicas"
                    _provenance: {
                        sourceBlueprint: "opm.dev/blueprints/workload@v1#StatelessWorkload"
                        traitHash:       "sha256:ghi789..."
                    }
                }

                "opm.dev/traits/health@v1#HealthCheck": {
                    name:        "HealthCheck"
                    kind:        "Trait"
                    #apiVersion: "opm.dev/traits/health@v1"
                    target: ["component"]
                    schema: {
                        liveness?: {
                            httpGet?: {
                                path!:   string
                                port!:   int
                                scheme?: "HTTP" | "HTTPS" | *"HTTP"
                            }
                            tcpSocket?: {
                                port!: int
                            }
                            exec?: {
                                command!: [...string]
                            }
                            initialDelaySeconds?: int | *0
                            periodSeconds?:       int | *10
                        }
                        readiness?: {
                            // Same structure as liveness
                        }
                    }
                    parentUnits: ["opm.dev/units/workload@v1#Container"]
                    description: "Health check configuration"
                    labels: {
                        "core.opm.dev/category": "workload"
                    }
                    #fullyQualifiedName: "opm.dev/traits/health@v1#HealthCheck"
                    _provenance: {
                        sourceBlueprint: "opm.dev/blueprints/workload@v1#StatelessWorkload"
                        traitHash:       "sha256:jkl012..."
                    }
                }
            }

            // Data fields (still use value references)
            container: {
                name:  "blog-frontend"
                image: values.frontend.image
                ports: {
                    http: {
                        targetPort: 3000
                        protocol:   "TCP"
                    }
                }
                env: {
                    DATABASE_URL: {
                        name:  "DATABASE_URL"
                        value: "postgresql://postgres:5432/blog"
                    }
                }
            }

            replicas: {
                count: values.frontend.replicas
            }

            healthCheck: {
                liveness: {
                    httpGet: {
                        path: "/health"
                        port: 3000
                    }
                }
            }
        }

        // Database: Flattened to primitives
        database: {
            #metadata: {
                name: "database"
                labels: {
                    component:                    "database"
                    tier:                         "data"
                    "core.opm.dev/category":      "data"
                    "core.opm.dev/workload-type": "stateful"
                }
                annotations: {
                    "opm.dev/origin-blueprint": "opm.dev/blueprints/data@v1#SimpleDatabase"
                    "opm.dev/composed-of": """
                        opm.dev/units/workload@v1#Container,
                        opm.dev/traits/workload@v1#RestartPolicy,
                        opm.dev/traits/workload@v1#UpdateStrategy,
                        opm.dev/traits/health@v1#HealthCheck,
                        opm.dev/units/storage@v1#Volume
                        """
                }
            }

            #units: {
                // Container Unit (inlined schema)
                "opm.dev/units/workload@v1#Container": {
                    // ... full inlined definition
                    // Note: Provenance metadata is optional/future feature
                    _provenance: {
                        sourceBlueprint: "opm.dev/blueprints/data@v1#SimpleDatabase"
                        viaBlueprint:    "opm.dev/blueprints/workload@v1#StatefulWorkload"
                        unitHash:        "sha256:def456..."
                    }
                }

                "opm.dev/units/storage@v1#Volume": {
                    name:        "Volume"
                    kind:        "Unit"
                    #apiVersion: "opm.dev/units/storage@v1"
                    target: ["component"]
                    #spec: {
                        volume: {
                        name!: string
                        persistentClaim?: {
                            accessMode!: "ReadWriteOnce" | "ReadOnlyMany" | "ReadWriteMany"
                            size!:       string
                            storageClass?: string
                        }
                        emptyDir?: {
                            sizeLimit?: string
                        }
                        configMap?: {
                            name!: string
                        }
                        secret?: {
                            name!: string
                        }
                    }
                    }
                    description: "Volume for persistent or ephemeral storage"
                    labels: {
                        "core.opm.dev/category": "data"
                    }
                    #fullyQualifiedName: "opm.dev/units/storage@v1#Volume"
                    _provenance: {
                        sourceBlueprint: "opm.dev/blueprints/data@v1#SimpleDatabase"
                        unitHash:        "sha256:mno345..."
                    }
                }
            }

            #traits: {
                "opm.dev/traits/workload@v1#RestartPolicy": {
                    // ... full inlined definition
                }

                "opm.dev/traits/workload@v1#UpdateStrategy": {
                    // ... full inlined definition
                }

                "opm.dev/traits/health@v1#HealthCheck": {
                    // ... full inlined definition
                }
            }

            // Data fields (generated from SimpleDatabase logic)
            container: {
                name:  "database"
                image: "postgres:15"
                ports: {
                    db: {
                        targetPort: 5432
                    }
                }
                env: {
                    DB_NAME: {
                        name:  "DB_NAME"
                        value: "blog"
                    }
                    DB_USER: {
                        name:  "DB_USER"
                        value: "admin"
                    }
                    DB_PASSWORD: {
                        name:  "DB_PASSWORD"
                        value: "changeme"
                    }
                }
                volumeMounts: dbData: {
                    name:      "dbData"
                    mountPath: "/var/lib/postgresql/data"
                }
            }

            restartPolicy: {
                policy: "Always"
            }

            updateStrategy: {
                type: "RollingUpdate"
            }

            healthCheck: {
                liveness: {
                    httpGet: {
                        path:   "/healthz"
                        port:   5432
                        scheme: "HTTP"
                    }
                }
            }

            volume: {
                dbData: {
                    name: "db-data"
                    persistentClaim: {
                        accessMode: "ReadWriteOnce"
                        size:       values.database.storageSize
                    }
                }
            }
        }
    }

    // Value constraints preserved
    values: {
        frontend: {
            image!:    string
            replicas!: int
        }
        database: {
            storageSize!: string
        }
    }
}
```

**Key Characteristics:**
- NO Blueprints (`#StatelessWorkload`, `#SimpleDatabase` removed)
- ONLY Units (`Container`, `Volume`) and Traits (`Replicas`, `HealthCheck`, etc.)
- All Unit and Trait schemas INLINED (not just FQN references)
- Provenance metadata tracks origin Blueprint
- Component data fields preserved (still reference `values`)
- Labels inherited from Blueprints
- Deterministic Unit/Trait ordering
- Still CUE (can have imports and references)

---

### 3. ModuleRelease (Deployment Artifact)

```cue
package blog

import (
    opm "github.com/open-platform-model/core"
)

blogAppRelease: opm.#ModuleRelease & {
    #metadata: {
        name:      "blog"
        namespace: "production"
        version:   "1.0.0"
        labels: {
            "app.name":    "blog"
            team:          "content"
            environment:   "production"
            "release.id":  "20251028-103000"
        }
        annotations: {
            "opm.dev/release-timestamp": "2025-10-28T10:30:00Z"
            "opm.dev/released-by":       "platform-cd-system"
        }
    }

    // Reference to the Module (IR)
    module: blogAppModule

    // CONCRETE VALUES (everything closed)
    values: {
        frontend: {
            image:    "blog-frontend:v1.2.3"
            replicas: 3
        }
        database: {
            storageSize: "10Gi"
        }
    }

    // Status tracking
    #status: {
        phase:      "deployed"
        conditions: [...]
    }
}
```

**Key Characteristics:**
- References Module (IR)
- All values are concrete (no constraints)
- Everything is closed (no optional fields)
- Ready for `cue export` to succeed
- Auditable & diffable
- Immutable deployment record

---

## Go Library Design

### Package Structure

```
pkg/
└── flatten/
    ├── flattener.go       # Main flattening logic
    ├── resolver.go        # Element resolution & inlining
    ├── compositor.go      # Composite → primitive expansion
    ├── provenance.go      # Metadata & tracking
    ├── hasher.go          # Deterministic hashing
    ├── types.go           # Go representations of CUE types
    └── flatten_test.go    # Unit tests
```

### Core Types

```go
package flatten

import (
    "cuelang.org/go/cue"
    "cuelang.org/go/cue/cuecontext"
    "time"
)

// Flattener handles ModuleDefinition → Module transformation
type Flattener struct {
    ctx          *cue.Context
    elementCache map[string]*Element  // Cache resolved elements
    hashCache    map[string]string    // Element hash cache
    version      string                // Flattener version
}

// Element represents a resolved element with inlined schema
type Element struct {
    FQN         string                 // Fully qualified name
    Name        string
    Kind        string                 // "primitive", "modifier", "composite"
    APIVersion  string
    Target      []string
    Schema      cue.Value              // Inlined schema
    Composes    []string               // For composites
    Modifies    []string               // For modifiers
    Labels      map[string]string
    Annotations map[string]string
    Description string
    Hash        string                 // Content hash for versioning
}

// Component represents a flattened component
type Component struct {
    Metadata    ComponentMetadata
    Elements    map[string]*Element    // Only primitives + modifiers
    DataFields  cue.Value              // The actual data
    Provenance  ProvenanceInfo
}

// ProvenanceInfo tracks flattening metadata
type ProvenanceInfo struct {
    SourceComposites []string           // Original composite FQNs
    FlattenedAt      time.Time
    FlattenerVersion string
    SourceHash       string              // Hash of source ModuleDefinition
    ElementHashes    map[string]string   // Hash per element
}

// FlattenOptions controls flattening behavior
type FlattenOptions struct {
    PreserveComments     bool
    IncludeProvenance    bool
    DeterministicOrdering bool
    ValidateAfterFlatten bool
}

// NewFlattener creates a new flattener instance
func NewFlattener(ctx *cue.Context, version string) *Flattener {
    return &Flattener{
        ctx:          ctx,
        elementCache: make(map[string]*Element),
        hashCache:    make(map[string]string),
        version:      version,
    }
}

// Flatten converts a ModuleDefinition to a Module (IR)
func (f *Flattener) Flatten(moduleDefValue cue.Value, opts FlattenOptions) (cue.Value, error) {
    // 1. Extract metadata
    metadata, err := f.extractMetadata(moduleDefValue)
    if err != nil {
        return cue.Value{}, fmt.Errorf("extract metadata: %w", err)
    }

    // 2. Process each component
    componentsIter, err := moduleDefValue.LookupPath(cue.ParsePath("components")).Fields()
    if err != nil {
        return cue.Value{}, fmt.Errorf("lookup components: %w", err)
    }

    flattenedComponents := make(map[string]*Component)

    for componentsIter.Next() {
        compID := componentsIter.Label()
        compValue := componentsIter.Value()

        // Flatten this component
        flatComp, err := f.flattenComponent(compID, compValue, opts)
        if err != nil {
            return cue.Value{}, fmt.Errorf("flatten component %s: %w", compID, err)
        }

        flattenedComponents[compID] = flatComp
    }

    // 3. Build output Module structure
    moduleValue, err := f.buildModuleValue(metadata, flattenedComponents, moduleDefValue, opts)
    if err != nil {
        return cue.Value{}, fmt.Errorf("build module value: %w", err)
    }

    // 4. Validate if requested
    if opts.ValidateAfterFlatten {
        if err := moduleValue.Validate(); err != nil {
            return cue.Value{}, fmt.Errorf("validation failed: %w", err)
        }
    }

    return moduleValue, nil
}

// flattenComponent processes a single component
func (f *Flattener) flattenComponent(id string, compValue cue.Value, opts FlattenOptions) (*Component, error) {
    comp := &Component{
        Elements:   make(map[string]*Element),
        Provenance: ProvenanceInfo{
            FlattenedAt:      time.Now(),
            FlattenerVersion: f.version,
            ElementHashes:    make(map[string]string),
        },
    }

    // Extract component metadata
    comp.Metadata = f.extractComponentMetadata(compValue)

    // Extract component Units
    unitsValue := compValue.LookupPath(cue.ParsePath("#units"))
    if unitsValue.Exists() {
        unitIter, _ := unitsValue.Fields()
        for unitIter.Next() {
            unitFQN := unitIter.Label()
            unitValue := unitIter.Value()
            // ... process unit ...
        }
    }

    // Extract component Traits
    traitsValue := compValue.LookupPath(cue.ParsePath("#traits"))
    if traitsValue.Exists() {
        traitIter, _ := traitsValue.Fields()
        for traitIter.Next() {
            traitFQN := traitIter.Label()
            traitValue := traitIter.Value()

            // Resolve this element
            resolvedElem, err := f.resolveElement(elemFQN, elemValue)
            if err != nil {
                return nil, fmt.Errorf("resolve element %s: %w", elemFQN, err)
            }

            // If composite, expand to primitives
            if resolvedElem.Kind == "composite" {
                primitives, err := f.expandComposite(resolvedElem)
                if err != nil {
                    return nil, fmt.Errorf("expand composite %s: %w", elemFQN, err)
                }

                // Add all primitives to component
                for _, prim := range primitives {
                    comp.Elements[prim.FQN] = prim
                    comp.Provenance.SourceComposites = append(
                        comp.Provenance.SourceComposites,
                        resolvedElem.FQN,
                    )
                }
            } else {
                // Primitive or modifier - add directly
                comp.Elements[resolvedElem.FQN] = resolvedElem
            }
        }
    }

    // Extract data fields (preserve as-is, including value references)
    comp.DataFields = compValue

    // Sort elements deterministically if requested
    if opts.DeterministicOrdering {
        comp.Elements = f.sortElements(comp.Elements)
    }

    return comp, nil
}

// expandBlueprint recursively expands a Blueprint to Units/Traits
func (f *Flattener) expandBlueprint(blueprint *Blueprint) ([]*Definition, error) {
    var definitions []*Definition

    for _, composedFQN := range blueprint.ComposedUnits {
        // Resolve composed Unit or Trait
        composedDef, err := f.resolveDefinitionByFQN(composedFQN)
        if err != nil {
            return nil, fmt.Errorf("resolve composed element %s: %w", composedFQN, err)
        }

        // Recursively expand if Blueprint
        if composedDef.Kind == "Blueprint" {
            subDefinitions, err := f.expandBlueprint(composedDef)
            if err != nil {
                return nil, fmt.Errorf("expand sub-composite %s: %w", composedFQN, err)
            }
            primitives = append(primitives, subPrimitives...)
        } else {
            // Add primitive or modifier
            primitives = append(primitives, composedElem)
        }
    }

    return primitives, nil
}

// resolveElement inlines element schema and computes hash
func (f *Flattener) resolveElement(fqn string, elemValue cue.Value) (*Element, error) {
    // Check cache first
    if cached, ok := f.elementCache[fqn]; ok {
        return cached, nil
    }

    elem := &Element{FQN: fqn}

    // Extract element fields
    elem.Name = elemValue.LookupPath(cue.ParsePath("name")).String()
    elem.Kind = elemValue.LookupPath(cue.ParsePath("kind")).String()
    elem.APIVersion = elemValue.LookupPath(cue.ParsePath("#apiVersion")).String()

    // Inline schema (this is the key operation)
    schemaValue := elemValue.LookupPath(cue.ParsePath("schema"))
    if schemaValue.Exists() {
        // Schema is now inlined in the element definition
        elem.Schema = schemaValue
    }

    // Extract composes/modifies
    if elem.Kind == "composite" {
        composesValue := elemValue.LookupPath(cue.ParsePath("composes"))
        if composesValue.Exists() {
            composesIter, _ := composesValue.List()
            for composesIter.Next() {
                elem.Composes = append(elem.Composes, composesIter.Value().String())
            }
        }
    } else if elem.Kind == "modifier" {
        modifiesValue := elemValue.LookupPath(cue.ParsePath("modifies"))
        if modifiesValue.Exists() {
            modifiesIter, _ := modifiesValue.List()
            for modifiesIter.Next() {
                elem.Modifies = append(elem.Modifies, modifiesIter.Value().String())
            }
        }
    }

    // Compute hash
    elem.Hash = f.computeElementHash(elem)

    // Cache and return
    f.elementCache[fqn] = elem
    return elem, nil
}

// buildModuleValue constructs the output Module CUE value
func (f *Flattener) buildModuleValue(
    metadata map[string]interface{},
    components map[string]*Component,
    originalModule cue.Value,
    opts FlattenOptions,
) (cue.Value, error) {
    // Build output structure in CUE
    // This will construct the Module schema shown in example above

    // Start with base module structure
    moduleBuilder := f.ctx.CompileString(`
        package generated

        import opm "github.com/open-platform-model/core"

        module: opm.#Module & {
            #metadata: _
            components: _
            values: _
        }
    `)

    // Add metadata with provenance annotations
    if opts.IncludeProvenance {
        metadata["annotations"].(map[string]string)["opm.dev/flattened"] = "true"
        metadata["annotations"].(map[string]string)["opm.dev/flattener"] = f.version
        // ... add more provenance
    }

    // Add each flattened component
    for compID, comp := range components {
        // Build component CUE structure
        // ...
    }

    // Preserve original values schema
    valuesValue := originalModule.LookupPath(cue.ParsePath("values"))
    // ... merge into output

    return moduleBuilder, nil
}
```

---

## Implementation Steps

### Phase 1: Core Flattening (Week 1-2)

**Goal**: Basic flattening working for simple cases

1. **Setup**
   - Create `pkg/flatten` package
   - Add CUE SDK dependencies
   - Create basic types

2. **Element Resolution**
   - Implement `resolveElement` (schema inlining)
   - Implement element caching
   - Add tests for primitive/modifier resolution

3. **Composite Expansion**
   - Implement `expandComposite` (recursive)
   - Handle nested composites (SimpleDatabase → StatefulWorkload → Container)
   - Add tests for StatelessWorkload → Container+Replicas

4. **Component Flattening**
   - Implement `flattenComponent`
   - Preserve data fields with value references
   - Add tests for full component flattening

**Deliverable**: `flattener.Flatten()` works for blog example

---

### Phase 2: Provenance & Hashing (Week 3)

**Goal**: Reproducibility and traceability

1. **Hash Implementation**
   - Implement `computeElementHash` (deterministic)
   - Hash entire ModuleDefinition for source tracking
   - Add hash verification on re-flatten

2. **Provenance Metadata**
   - Track origin composite for each element
   - Track flattening timestamp and version
   - Add to component annotations

3. **Deterministic Ordering**
   - Sort elements by FQN lexicographically
   - Ensure stable output for diffs

**Deliverable**: Module output is deterministic and traceable

---

### Phase 3: CUE Value Construction (Week 4)

**Goal**: Output valid CUE that matches Module schema

1. **Module Builder**
   - Implement `buildModuleValue`
   - Construct CUE structure matching `#Module` schema
   - Preserve imports and references

2. **Component Builder**
   - Serialize flattened components to CUE
   - Include inlined element definitions
   - Preserve data fields exactly

3. **Validation**
   - Validate output against `#Module` schema
   - Ensure all required fields present
   - Test with CUE vet

**Deliverable**: Output can be loaded as valid Module

---

### Phase 4: CLI Integration (Week 5-6)

**Goal**: Make flattening part of OPM workflow

1. **CLI Command**
   ```bash
   opm mod flatten input.cue --output module-ir.cue
   ```

2. **Publishing Workflow**
   ```bash
   # Developer workflow
   cue fmt definition.cue
   opm mod flatten definition.cue --output module.cue
   opm mod publish module.cue --registry localhost:5000 --version v1.0.0
   ```

3. **Build Command Update**
   ```bash
   # CLI now loads Module (IR) instead of ModuleDefinition
   opm mod build module.cue --values prod-values.cue --output ./k8s
   ```

**Deliverable**: Full workflow from authoring to deployment

---

### Phase 5: Schema Changes (Week 7)

**Goal**: Update core schemas to support IR

1. **Add Module (IR) Schema**
   ```cue
   // core/module.cue

   #Module: close({
       apiVersion: "opm.dev/core/module@v1"
       kind:       "Module"
       #metadata: {
           // Same as ModuleDefinition
           annotations: {
               "opm.dev/flattened"?:    bool
               "opm.dev/flattener"?:    string
               "opm.dev/source-hash"?:  string
               "opm.dev/flattened-at"?: string
           }
       }

       components: [Id=string]: #ComponentIR
       values: {...}
   })

   #ComponentIR: {
       #metadata: {
           // Standard metadata
           annotations: {
               "opm.dev/origin-composite"?: string
               "opm.dev/composed-of"?:      string
           }
       }

       // Only Units and Traits allowed (Blueprints are flattened)
       #units: [FQN=string]: #UnitDefinition & {
           kind: "Unit"

           // Provenance tracking (optional/future)
           _provenance?: {
               sourceBlueprint?: string
               viaBlueprint?:    string
               unitHash!:        string
           }
       }
       #traits?: [FQN=string]: #TraitDefinition & {
           kind: "Trait"

           // Provenance tracking (optional/future)
           _provenance?: {
               sourceBlueprint?: string
               traitHash!:       string
           }
       }

       // Data fields (preserved from source)
       ...
   }
   ```

2. **Add ModuleRelease Schema**
   ```cue
   #ModuleRelease: close({
       apiVersion: "opm.dev/core/module@v1"
       kind:       "ModuleRelease"
       #metadata: {
           namespace!: string
           labels: {
               "release.id"?: string
           }
           annotations: {
               "opm.dev/release-timestamp"?: string
               "opm.dev/released-by"?:       string
           }
       }

       // Reference to Module (IR)
       #module!: #ModuleIR

       // Concrete values (everything closed)
       values!: {...} & #module.values

       #status: {
           phase!: "pending" | "deployed" | "failed"
           conditions?: [...]
       }
   })
   ```

---

### Phase 6: Testing & Documentation (Week 8)

1. **Comprehensive Tests**
   - Unit tests for each function
   - Integration tests for full pipeline
   - Test with all Blueprints
   - Performance benchmarks

2. **Documentation**
   - Update CLAUDE.md with flattening concept
   - Add examples showing all three layers
   - Document Go API
   - Write migration guide

**Deliverable**: Production-ready flattening system

---

## Testing Strategy

### Unit Tests

```go
func TestFlattenSimpleStateless(t *testing.T) {
    ctx := cuecontext.New()
    flattener := NewFlattener(ctx, "v0.1.0")

    // Load ModuleDefinition with StatelessWorkload
    moduleDefSource := `
    package test
    import opm "opm.dev/core@v1"
    import blueprints "opm.dev/blueprints@v1"

    myModule: opm.#ModuleDefinition & {
        #components: {
            app: blueprints.#StatelessWorkload & {
                statelessWorkload: {
                    container: {name: "app", image: "nginx"}
                }
            }
        }
    }
    `

    moduleDefValue := ctx.CompileString(moduleDefSource)

    // Flatten
    moduleValue, err := flattener.Flatten(
        moduleDefValue.LookupPath(cue.ParsePath("myModule")),
        FlattenOptions{
            IncludeProvenance:     true,
            DeterministicOrdering: true,
        },
    )
    require.NoError(t, err)

    // Verify output
    components := moduleValue.LookupPath(cue.ParsePath("components"))
    appComp := components.LookupPath(cue.ParsePath("app"))

    // Should have Container Unit, Replicas Trait, etc. as separate definitions
    units := appComp.LookupPath(cue.ParsePath("#units"))
    traits := appComp.LookupPath(cue.ParsePath("#traits"))

    container := units.LookupPath(cue.ParsePath("opm.dev/units/workload@v1#Container"))
    require.True(t, container.Exists())
    require.Equal(t, "Unit", container.LookupPath(cue.ParsePath("kind")).String())

    replicas := traits.LookupPath(cue.ParsePath("opm.dev/traits/scaling@v1#Replicas"))
    require.True(t, replicas.Exists())
    require.Equal(t, "Trait", replicas.LookupPath(cue.ParsePath("kind")).String())

    // Verify provenance
    annotations := appComp.LookupPath(cue.ParsePath("metadata.annotations"))
    originBlueprint := annotations.LookupPath(cue.ParsePath("opm.dev/origin-blueprint")).String()
    require.Equal(t, "opm.dev/blueprints/workload@v1#StatelessWorkload", originBlueprint)
}

func TestExpandNestedComposite(t *testing.T) {
    // Test SimpleDatabase → StatefulWorkload → Container+Volume
    // Verify recursive expansion works correctly
}

func TestDeterministicOutput(t *testing.T) {
    // Flatten same module twice
    // Verify byte-for-byte identical output
}

func TestHashStability(t *testing.T) {
    // Compute hash for same element multiple times
    // Verify hash is stable
}
```

---

## Performance Characteristics

### Current (Without Flattening)

- **CLI Load Time**: 2-5 seconds for medium module
  - Parse ModuleDefinition CUE
  - Load entire element registry
  - Recursively resolve composites at runtime
  - Match transformers

### With Flattening

- **Flatten Time** (one-time cost): 5-10 seconds
  - Parse ModuleDefinition
  - Resolve all composites
  - Inline all schemas
  - Generate Module (IR)

- **CLI Load Time** (every build): < 1 second
  - Load pre-flattened Module (IR)
  - No composite resolution needed
  - Direct transformer matching
  - **50-80% faster**

### Memory

- **Current**: High (full element registry in memory)
- **With Flattening**: Lower (only used primitives/modifiers in Module)

---

## Migration Path

### For Platform Teams

```bash
# 1. Flatten existing ModuleDefinitions
opm mod flatten old-definitions/*.cue --output modules/

# 2. Publish Modules (IR) to registry
cd modules
opm mod publish blog-module.cue --version v1.0.0

# 3. Update platform catalogs to reference Modules (IR)
# Platform teams curate Modules, not ModuleDefinitions
```

### For Developers

```bash
# Authoring (no change - still write ModuleDefinitions)
vim my-app-definition.cue

# Build locally (CLI handles flattening internally)
opm mod build my-app-definition.cue --output ./k8s

# Publish to platform catalog
opm mod publish my-app-definition.cue --flatten --version v2.0.0
#                                      ^^^^^^^^^ CLI flattens before publishing
```

### Backward Compatibility

- CLI can detect if input is ModuleDefinition or Module (check `#kind`)
- If ModuleDefinition: flatten on-the-fly (dev workflow)
- If Module: use directly (production workflow)

---

## Example CLI Commands

```bash
# Flatten a ModuleDefinition
opm mod flatten definition.cue --output module.cue

# With options
opm mod flatten definition.cue \
    --output module.cue \
    --include-provenance \
    --verify-hash

# Build from flattened Module (fast path)
opm mod build module.cue --values prod.cue --output ./k8s

# Build from ModuleDefinition (dev path - flattens on-the-fly)
opm mod build definition.cue --values dev.cue --output ./k8s

# Publish with flattening
opm mod publish definition.cue \
    --registry localhost:5000 \
    --version v1.0.0 \
    --flatten

# Inspect a Module
opm mod inspect module.cue
# Output:
# Kind: ModuleIR
# Version: 1.0.0
# Flattened: true
# Flattener: opm-flatten@v0.1.0
# Source Hash: sha256:abc123...
# Components: 2
#   - frontend (3 primitives, 2 modifiers)
#   - database (2 primitives, 3 modifiers)

# Diff two Modules
opm mod diff module-v1.cue module-v2.cue
# Shows element changes, schema changes, data changes

# Validate a Module
opm mod validate module.cue
# Verifies:
# - Conforms to #Module schema
# - All Unit/Trait hashes valid
# - No Blueprints present (all flattened)
# - All references resolvable
```

---

## Benefits Summary

### For Developers
- ✅ Still write high-level composites
- ✅ No cognitive overhead from flattening
- ✅ Faster local builds (CLI handles flattening)

### For Platform Teams
- ✅ Distribute optimized Modules (IR)
- ✅ Faster runtime (no composite resolution)
- ✅ Traceable (provenance metadata)
- ✅ Auditable (deterministic hashes)

### For Transformers
- ✅ Only deal with primitives/modifiers
- ✅ Simple matching logic
- ✅ Composability guaranteed

### For System
- ✅ 50-80% faster CLI operations
- ✅ Lower memory usage
- ✅ Hermetic modules (all schemas inlined)
- ✅ Versionable (hash-based)

---

## Next Steps

1. **Review this plan** - Confirm approach aligns with vision
2. **Create GitHub issues** - Break down into trackable work
3. **Spike implementation** - Prototype Phase 1 core flattening
4. **Validate with examples** - Test with blog, supabase examples
5. **Iterate on design** - Refine based on learnings
6. **Full implementation** - Execute all 6 phases

---

## Questions to Resolve

1. **Schema Versioning**: Should Module (IR) have its own API version or inherit from ModuleDefinition?
2. **Import Handling**: How to handle CUE imports in flattened output? Keep all imports or minimize?
3. **Custom Elements**: How to handle `kind: "custom"` elements in flattening?
4. **Partial Flattening**: Should we support flattening only some components?
5. **Cache Strategy**: Should CLI cache flattened Modules or flatten on-demand?

---

## Appendix: Key Files to Modify

### Core Repository

- [ ] `core/module.cue` - Add `#ModuleIR` and `#ModuleRelease` schemas
- [ ] `core/element.cue` - Add `_provenance` field to `#Element`
- [ ] `core/CLAUDE.md` - Document flattening concept

### CLI Repository

- [ ] `cli/pkg/flatten/` - New package (all flattening logic)
- [ ] `cli/cmd/opm/mod_flatten.go` - New command
- [ ] `cli/cmd/opm/mod_build.go` - Update to support Module (IR)
- [ ] `cli/cmd/opm/mod_publish.go` - Add --flatten flag
- [ ] `cli/pkg/loader/loader.go` - Detect ModuleDefinition vs Module
- [ ] `cli/pkg/registry/registry.go` - Handle Module (IR) in registry

### Documentation

- [ ] Update all examples to show both ModuleDefinition and Module (IR)
- [ ] Add migration guide
- [ ] Add flattening architecture doc

---

**End of Implementation Plan**
