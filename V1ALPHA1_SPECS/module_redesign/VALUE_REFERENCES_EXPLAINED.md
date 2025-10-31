# Value References Through the Flattening Pipeline

## The Question

How are references to `values` in ModuleDefinition components preserved during flattening so that ModuleRelease can make them concrete?

## The Answer

**Value references are CUE expressions that get preserved exactly as-is during flattening.**

The flattener only removes composites and inlines schemas. It does NOT evaluate or resolve value references - those remain as symbolic CUE paths until ModuleRelease provides concrete values.

---

## Complete Example: Value References Through All Layers

### Layer 1: ModuleDefinition (Authored by Developers and/or Platform Teams)

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
    }

    components: {
        frontend: {
            blueprints.#StatelessWorkload

            statelessWorkload: {
                container: {
                    name:  "blog-frontend"
                    image: values.frontend.image        // ← VALUE REFERENCE
                    ports: {
                        http: {
                            targetPort: 3000
                        }
                    }
                }
                replicas: {
                    count: values.frontend.replicas     // ← VALUE REFERENCE
                }
            }
        }

        database: {
            blueprints.#SimpleDatabase

            simpleDatabase: {
                engine:   "postgres"
                version:  "15"
                dbName:   "blog"
                username: "admin"
                password: "changeme"
                persistence: {
                    enabled: true
                    size:    values.database.storageSize  // ← VALUE REFERENCE
                }
            }
        }
    }

    // Value schema (constraints, no defaults)
    values: {
        frontend: {
            image!:    string      // Required
            replicas!: int & >0    // Required, must be positive
        }
        database: {
            storageSize!: string & =~"^[0-9]+Gi$"  // Required, must be Gi format
        }
    }
}
```

**Key Point**: `values.frontend.image` is a CUE path expression, not a concrete value.

---

### Layer 2: Module (IR) - After Flattening

```cue
package blog

import opm "github.com/open-platform-model/core"

blogAppModule: opm.#ModuleIR & {
    #metadata: {
        name:    "blog"
        version: "1.0.0"
        annotations: {
            "opm.dev/flattened": "true"
            "opm.dev/flattener": "v0.1.0"
        }
    }

    components: {
        frontend: {
            #metadata: {
                name: "frontend"
                annotations: {
                    "opm.dev/origin-blueprint": "opm.dev/blueprints/workload@v1#StatelessWorkload"
                }
            }

            // Blueprints removed, only Units and Traits remain
            #units: {
                "opm.dev/units/workload@v1#Container": {
                    name:        "Container"
                    kind:        "Unit"
                    #apiVersion: "opm.dev/units/workload@v1"

                    // Schema FULLY INLINED
                    schema: {
                        name!:  string
                        image!: string
                        ports?: [portName=string]: {
                            targetPort!: int
                            protocol:    "TCP" | "UDP" | *"TCP"
                        }
                        // ... full schema
                    }
                }
            }

            #traits: {
                "opm.dev/traits/scaling@v1#Replicas": {
                    name:        "Replicas"
                    kind:        "Trait"
                    #apiVersion: "opm.dev/traits/scaling@v1"

                    schema: {
                        count: int | *1
                    }
                }
            }

            // DATA FIELDS - VALUE REFERENCES PRESERVED EXACTLY AS-IS
            container: {
                name:  "blog-frontend"
                image: values.frontend.image        // ← STILL A REFERENCE!
                ports: {
                    http: {
                        targetPort: 3000            // ← Concrete value
                    }
                }
            }

            replicas: {
                count: values.frontend.replicas     // ← STILL A REFERENCE!
            }
        }

        database: {
            #metadata: {
                name: "database"
                annotations: {
                    "opm.dev/origin-blueprint": "opm.dev/blueprints/data@v1#SimpleDatabase"
                }
            }

            #units: {
                "opm.dev/units/workload@v1#Container": {
                    // ... inlined schema
                }
                "opm.dev/units/storage@v1#Volume": {
                    // ... inlined schema
                }
            }
            #traits: {
                // ... other Traits
            }

            // DATA FIELDS - VALUE REFERENCES PRESERVED
            container: {
                name:  "database"
                image: "postgres:15"                // ← Concrete (from composite logic)
                ports: db: {targetPort: 5432}
                env: {
                    DB_NAME: {
                        name:  "DB_NAME"
                        value: "blog"               // ← Concrete
                    }
                    DB_USER: {
                        name:  "DB_USER"
                        value: "admin"              // ← Concrete
                    }
                }
            }

            volume: dbData: {
                name: "db-data"
                persistentClaim: {
                    accessMode: "ReadWriteOnce"
                    size:       values.database.storageSize  // ← STILL A REFERENCE!
                }
            }
        }
    }

    // VALUES SCHEMA PRESERVED EXACTLY
    values: {
        frontend: {
            image!:    string
            replicas!: int & >0
        }
        database: {
            storageSize!: string & =~"^[0-9]+Gi$"
        }
    }
}
```

**Key Points**:
- ✅ Blueprints removed (`#StatelessWorkload`, `#SimpleDatabase`)
- ✅ Unit and Trait schemas inlined
- ✅ **Value references preserved as CUE paths** (`values.frontend.image`)
- ✅ Values schema preserved unchanged
- ✅ Mixed concrete values and references coexist

---

### Layer 3: ModuleRelease - Values Become Concrete

```cue
package blog

import opm "github.com/open-platform-model/core"

blogAppRelease: opm.#ModuleRelease & {
    #metadata: {
        name:      "blog"
        namespace: "production"
        version:   "1.0.0"
        labels: {
            environment: "production"
        }
    }

    // Reference the Module (IR)
    #module: blogAppModule

    // PROVIDE CONCRETE VALUES
    values: {
        frontend: {
            image:    "registry.example.com/blog-frontend:v1.2.3"  // ← CONCRETE
            replicas: 3                                             // ← CONCRETE
        }
        database: {
            storageSize: "50Gi"                                     // ← CONCRETE
        }
    }
}
```

**What Happens Now**: CUE's unification resolves all references:

```cue
// CUE evaluates:
blogAppRelease.#module.components.frontend.container.image
// = values.frontend.image
// = blogAppRelease.values.frontend.image
// = "registry.example.com/blog-frontend:v1.2.3"

blogAppRelease.#module.components.frontend.replicas.count
// = values.frontend.replicas
// = blogAppRelease.values.frontend.replicas
// = 3

blogAppRelease.#module.components.database.volume.dbData.persistentClaim.size
// = values.database.storageSize
// = blogAppRelease.values.database.storageSize
// = "50Gi"
```

---

## How Flattening Preserves References

### In the Go Flattener

```go
// flattenComponent processes a single component
func (f *Flattener) flattenComponent(id string, compValue cue.Value) (*ComponentIR, error) {
    comp := &ComponentIR{
        ID:         id,
        Units:      make(map[string]*Unit),
        Traits:     make(map[string]*Trait),
    }

    // 1. Extract and flatten definitions (Blueprints → Units + Traits)
    unitsValue := compValue.LookupPath(cue.ParsePath("#units"))
    traitsValue := compValue.LookupPath(cue.ParsePath("#traits"))
    // ... expand Blueprints, inline schemas ...

    // 2. PRESERVE DATA FIELDS AS-IS
    // Key: We DO NOT evaluate the CUE value, we preserve the AST
    comp.DataFields = compValue  // ← This preserves the SYNTAX TREE

    // When we generate output CUE, we serialize the AST, not the evaluated value
    // This means references like `values.frontend.image` remain as references

    return comp, nil
}

// buildModuleValue constructs output CUE
func (f *Flattener) buildModuleValue(
    originalModule cue.Value,
    components map[string]*ComponentIR,
) (cue.Value, error) {
    // For each component's data fields...
    for _, comp := range components {
        // Extract data fields WITHOUT EVALUATING
        dataIter, _ := comp.DataFields.Fields(cue.All())
        for dataIter.Next() {
            fieldName := dataIter.Label()
            fieldValue := dataIter.Value()

            // Check if this field is a reference or concrete
            if fieldValue.Kind() == cue.StructKind {
                // Recursively preserve structure
                // ...
            } else {
                // Preserve the SYNTAX, not the evaluation
                // Use fieldValue.Syntax() to get AST node
                syntaxNode := fieldValue.Syntax()

                // Examples:
                // - `values.frontend.image` → ast.SelectorExpr
                // - `"nginx:latest"` → ast.BasicLit
                // - `3000` → ast.BasicLit

                // Write syntaxNode to output (preserves references!)
            }
        }
    }

    // ALSO PRESERVE VALUES SCHEMA
    valuesValue := originalModule.LookupPath(cue.ParsePath("values"))
    // Serialize valuesValue.Syntax() to output

    return outputValue, nil
}
```

**Critical Insight**: We use `cue.Value.Syntax()` to get the Abstract Syntax Tree, not `cue.Value.String()` which evaluates.

---

## CUE Mechanism: How References Work

### CUE Unification

CUE's core operation is **unification**: combining constraints and values.

```cue
// Define a reference
container: {
    image: values.frontend.image
}

// Define the value schema
values: {
    frontend: {
        image!: string
    }
}

// Later, provide concrete value
values: {
    frontend: {
        image: "nginx:latest"  // Unifies with the constraint above
    }
}

// CUE resolves: container.image = "nginx:latest"
```

**Key Properties**:
1. References are **symbolic paths** in the CUE lattice
2. They remain unresolved until all parts are unified
3. CUE validates constraints during unification
4. Order doesn't matter (declarative)

### In Our Pipeline

```cue
// Module (IR) contains:
container: {
    image: values.frontend.image  // Unresolved reference
}
values: {
    frontend: {
        image!: string  // Constraint
    }
}

// ModuleRelease adds:
#module: <Module IR above>
values: {
    frontend: {
        image: "nginx:latest"  // Concrete value
    }
}

// CUE unifies:
// - ModuleRelease.#module.container.image
// - = values.frontend.image (from Module IR)
// - = ModuleRelease.values.frontend.image
// - = "nginx:latest"
// - Must satisfy: string constraint ✓
```

---

## Practical Examples

### Example 1: Simple Reference

**ModuleDefinition**:
```cue
components: {
    api: {
        container: {
            image: values.api.image  // Reference
        }
    }
}
values: {
    api: {
        image!: string  // Constraint
    }
}
```

**Module (IR)** (after flattening):
```cue
components: {
    api: {
        #units: { /* Units only */ }
        #traits: { /* Traits only */ }

        container: {
            image: values.api.image  // ← PRESERVED AS-IS
        }
    }
}
values: {
    api: {
        image!: string  // ← PRESERVED AS-IS
    }
}
```

**ModuleRelease**:
```cue
#module: <Module IR above>
values: {
    api: {
        image: "myapi:v1.0.0"  // ← CONCRETE
    }
}
// Result: api.container.image = "myapi:v1.0.0"
```

### Example 2: Conditional Reference

**ModuleDefinition**:
```cue
components: {
    db: {
        volume: dbData: {
            if values.db.persistence.enabled {
                persistentClaim: {
                    size: values.db.persistence.size
                }
            }
        }
    }
}
values: {
    db: {
        persistence: {
            enabled!: bool
            size!:    string
        }
    }
}
```

**Module (IR)**:
```cue
components: {
    db: {
        #units: { /* Units only */ }
        #traits: { /* Traits only */ }

        volume: dbData: {
            // CONDITIONAL PRESERVED
            if values.db.persistence.enabled {
                persistentClaim: {
                    size: values.db.persistence.size  // ← REFERENCE PRESERVED
                }
            }
        }
    }
}
values: {
    db: {
        persistence: {
            enabled!: bool
            size!:    string
        }
    }
}
```

**ModuleRelease**:
```cue
#module: <Module IR above>
values: {
    db: {
        persistence: {
            enabled: true      // ← CONCRETE
            size:    "100Gi"   // ← CONCRETE
        }
    }
}
// Result: db.volume.dbData.persistentClaim.size = "100Gi"
```

### Example 3: Complex Expression

**ModuleDefinition**:
```cue
components: {
    app: {
        container: {
            // Complex expression with reference
            image: "\(values.registry.host)/\(values.app.name):\(values.app.version)"
        }
    }
}
values: {
    registry: {host!: string}
    app: {
        name!:    string
        version!: string
    }
}
```

**Module (IR)**:
```cue
components: {
    app: {
        #units: { /* Units */ }
        #traits: { /* Traits */ }

        container: {
            // EXPRESSION PRESERVED (string interpolation)
            image: "\(values.registry.host)/\(values.app.name):\(values.app.version)"
        }
    }
}
values: {
    registry: {host!: string}
    app: {
        name!:    string
        version!: string
    }
}
```

**ModuleRelease**:
```cue
#module: <Module IR above>
values: {
    registry: {host: "registry.example.com"}
    app: {
        name:    "myapp"
        version: "v2.0.0"
    }
}
// Result: app.container.image = "registry.example.com/myapp:v2.0.0"
```

---

## Implementation Details

### Key Functions in Flattener

```go
// preserveDataField preserves a field's syntax without evaluation
func (f *Flattener) preserveDataField(fieldValue cue.Value) (ast.Expr, error) {
    // Get AST node (preserves references)
    syntaxNode := fieldValue.Syntax(
        cue.Docs(true),      // Preserve comments
        cue.Attributes(true), // Preserve attributes
        cue.Optional(true),   // Preserve optional fields
        cue.Concrete(false),  // DO NOT require concrete values
    )

    return syntaxNode, nil
}

// serializeComponent writes component to output CUE
func (f *Flattener) serializeComponent(comp *ComponentIR) (string, error) {
    var sb strings.Builder

    // Serialize Units (inlined schemas)
    sb.WriteString("#units: {\n")
    for fqn, unit := range comp.Units {
        sb.WriteString(fmt.Sprintf("  \"%s\": {\n", fqn))
        // ... write unit fields ...

        // Inline schema
        schemaSyntax := elem.Schema.Syntax()
        schemaBytes, _ := format.Node(schemaSyntax)
        sb.WriteString(fmt.Sprintf("    schema: %s\n", schemaBytes))

        sb.WriteString("  }\n")
    }
    sb.WriteString("}\n")

    // Serialize data fields (PRESERVE REFERENCES)
    dataIter, _ := comp.DataFields.Fields(cue.All())
    for dataIter.Next() {
        fieldName := dataIter.Label()
        fieldValue := dataIter.Value()

        // Get syntax (preserves references like `values.x.y`)
        fieldSyntax := fieldValue.Syntax()
        fieldBytes, _ := format.Node(fieldSyntax)

        sb.WriteString(fmt.Sprintf("%s: %s\n", fieldName, fieldBytes))
    }

    return sb.String(), nil
}
```

### What Gets Preserved

| Data Type | Preservation Strategy | Example |
|---------|----------------------|---------|
| **Concrete values** | Serialize as-is | `"nginx:latest"`, `3000`, `true` |
| **Simple references** | Preserve path | `values.frontend.image` |
| **Nested references** | Preserve path | `values.db.persistence.size` |
| **Conditionals** | Preserve condition | `if values.x { ... }` |
| **String interpolation** | Preserve template | `"\(values.host)/app"` |
| **Computations** | Preserve expression | `values.count * 2` |
| **Defaults** | Preserve disjunction | `values.x | *3` |

---

## Validation Flow

### In Module (IR)

```cue
// Module defines constraints
components: {
    api: {
        container: {
            image: values.api.image  // Reference (not concrete yet)
        }
    }
}

values: {
    api: {
        image!: string & =~"^[a-z0-9.-]+:[a-z0-9.-]+$"  // Constraint
        //      ^^^^^^   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        //      Required   Must match image format
    }
}

// ✓ This validates successfully:
//   - Reference is well-formed
//   - Constraint is valid
//   - NOT checked: whether image will be provided (that's for ModuleRelease)
```

### In ModuleRelease

```cue
#module: <Module IR with constraint above>

values: {
    api: {
        image: "nginx:latest"  // Concrete value
    }
}

// CUE validates:
// 1. ✓ Value is string
// 2. ✓ Value matches regex pattern
// 3. ✓ All required fields provided
// 4. ✓ Reference resolves to concrete value

// If validation fails:
values: {
    api: {
        image: "invalid_image_name"  // Missing ':'
    }
}
// ✗ Error: value "invalid_image_name" does not match pattern "^[a-z0-9.-]+:[a-z0-9.-]+$"

values: {
    api: {
        // image field omitted
    }
}
// ✗ Error: field 'image' is required
```

---

## Summary

### The Mechanism

1. **ModuleDefinition**: Contains value references as CUE path expressions
2. **Flattening**: Preserves AST (syntax tree) of data fields, including references
3. **Module (IR)**: References remain as symbolic paths, schemas are inlined
4. **ModuleRelease**: Provides concrete values, CUE unifies and resolves references

### Why It Works

- CUE references are **first-class syntax constructs**, not string templates
- The flattener operates on **AST nodes**, not evaluated values
- CUE's **unification** handles reference resolution at evaluation time
- **Constraints** travel with references through the pipeline

### Benefits

- ✅ **Type safety preserved**: Validation constraints stay active
- ✅ **Performance**: References don't add evaluation cost (they're lazy)
- ✅ **Flexibility**: Same Module (IR) works with different concrete values
- ✅ **Auditable**: Clear separation between template (Module) and instance (Release)

---

## Code Reference

See `examples/flattener_example.go`:
- Line 234-253: `preserveDataField()` implementation
- Line 300-320: Component serialization with reference preservation
- Line 156-180: Component flattening that preserves data fields

The key is using `cue.Value.Syntax()` instead of evaluating to strings.
