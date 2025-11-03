# Value References: Visual Flow

## The Core Mechanism

```
┌─────────────────────────────────────────────────────────────┐
│ ModuleDefinition (Layer 1)                                  │
├─────────────────────────────────────────────────────────────┤
│ components: {                                               │
│   api: {                                                    │
│     #StatelessWorkload  ← COMPOSITE                         │
│                                                             │
│     statelessWorkload: {                                    │
│       container: {                                          │
│         image: values.api.image  ← REFERENCE (not concrete) │
│                ^^^^^^^^^^^^^^^^                             │
│                This is a CUE path expression                │
│       }                                                     │
│       replicas: {count: values.api.replicas}                │
│     }                                                       │
│   }                                                         │
│ }                                                           │
│                                                             │
│ values: {                                                   │
│   api: {                                                    │
│     image!: string     ← CONSTRAINT (not concrete)          │
│     replicas!: int     ← CONSTRAINT (not concrete)          │
│   }                                                         │
│ }                                                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ FLATTEN
                            │ ▪ Remove #StatelessWorkload Blueprint
                            │ ▪ Expand to Container Unit + Replicas Trait
                            │ ▪ Inline Unit and Trait schemas
                            │ ▪ PRESERVE data field AST (including references!)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Module (IR) (Layer 2)                                       │
├─────────────────────────────────────────────────────────────┤
│ components: {                                               │
│   api: {                                                    │
│     #units: {                                               │
│       "...Container": {                                     │
│         kind: "Unit"                                        │
│         schema: {          ← INLINED (no lookup needed)     │
│           image!: string                                    │
│           // ... full schema                                │
│         }                                                   │
│       }                                                     │
│     }                                                       │
│     #traits: {                                              │
│       "...Replicas": {                                      │
│         kind: "Trait"                                       │
│         schema: {count: int}                                │
│       }                                                     │
│     }                                                       │
│                                                             │
│     // Data fields - REFERENCES PRESERVED                   │
│     container: {                                            │
│       image: values.api.image  ← STILL A REFERENCE!         │
│              ^^^^^^^^^^^^^^^^                               │
│              AST node preserved (not evaluated)             │
│     }                                                       │
│     replicas: {count: values.api.replicas}                  │
│   }                                                         │
│ }                                                           │
│                                                             │
│ values: {                                                   │
│   api: {                                                    │
│     image!: string     ← CONSTRAINT PRESERVED               │
│     replicas!: int     ← CONSTRAINT PRESERVED               │
│   }                                                         │
│ }                                                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ BIND
                            │ ▪ Reference Module (IR)
                            │ ▪ Provide concrete values
                            │ ▪ CUE unifies and resolves references
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ ModuleRelease (Layer 3)                                     │
├─────────────────────────────────────────────────────────────┤
│ module: <Module IR above>                                  │
│                                                             │
│ values: {                                                   │
│   api: {                                                    │
│     image: "nginx:v1.2.3"  ← CONCRETE VALUE                 │
│     replicas: 3            ← CONCRETE VALUE                 │
│   }                                                         │
│ }                                                           │
│                                                             │
│ ┌─────────────────────────────────────────────┐             │
│ │ CUE Unification Engine Resolves:            │             │
│ │                                             │             │
│ │ #module.components.api.container.image      │             │
│ │   = values.api.image (from Module IR)       │             │
│ │   = ModuleRelease.values.api.image          │             │
│ │   = "nginx:v1.2.3" ✓                        │             │
│ │                                             │             │
│ │ Validates: string constraint satisfied ✓    │             │
│ └─────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ EXPORT
                            │ cue export (validates & makes concrete)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Final Output (JSON/YAML)                                    │
├─────────────────────────────────────────────────────────────┤
│ {                                                           │
│   "api": {                                                  │
│     "container": {                                          │
│       "image": "nginx:v1.2.3"  ← CONCRETE                   │
│     },                                                      │
│     "replicas": {                                           │
│       "count": 3               ← CONCRETE                   │
│     }                                                       │
│   }                                                         │
│ }                                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Insight: AST Preservation

```
┌──────────────────────────────────────────────────────┐
│ What the Flattener Does NOT Do:                      │
├──────────────────────────────────────────────────────┤
│ ✗ Evaluate value references                         │
│ ✗ Resolve symbolic paths                            │
│ ✗ Replace references with concrete values           │
│ ✗ Template/substitute strings                       │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ What the Flattener DOES Do:                          │
├──────────────────────────────────────────────────────┤
│ ✓ Preserve Abstract Syntax Tree (AST)               │
│ ✓ Keep references as selector expressions           │
│ ✓ Maintain value schema constraints                 │
│ ✓ Remove Blueprint wrappers                         │
│ ✓ Inline Unit/Trait schemas                         │
└──────────────────────────────────────────────────────┘
```

---

## CUE's Three Representations

```
┌─────────────────┐
│ SOURCE CODE     │  "image: values.api.image"
│ (what you write)│
└────────┬────────┘
         │ parse
         ▼
┌─────────────────┐
│ AST (syntax)    │  SelectorExpr{
│ (structure)     │    X: Ident("values"),
│                 │    Sel: SelectorExpr{
│                 │      X: Ident("api"),
│                 │      Sel: Ident("image")
│                 │    }
│                 │  }
└────────┬────────┘
         │ evaluate
         ▼
┌─────────────────┐
│ VALUE (unified) │  "nginx:v1.2.3" (after providing concrete values)
│ (concrete data) │
└─────────────────┘

FLATTENER WORKS ON AST
├─ Input:  cue.Value (has AST + partial evaluation)
├─ Access: value.Syntax() → AST node
├─- Output: AST node (references preserved)
└─ CUE:    Unifies later when concrete values provided
```

---

## Example: Reference Flow

### Input to Flattener

```cue
// Go code receives this as cue.Value
container: {
    image: values.api.image
    //     ^^^^^^^^^^^^^^^^
    //     This is ast.SelectorExpr in the AST
}
```

### Flattener Processing

```go
// Get the field value
imageField := containerValue.LookupPath(cue.ParsePath("image"))

// DON'T DO THIS (would try to evaluate):
// imageStr, _ := imageField.String()  // ERROR: incomplete value
// imageStr would be "_|_" (bottom/error)

// DO THIS (preserve syntax):
imageSyntax := imageField.Syntax()  // Returns ast.SelectorExpr
// imageSyntax = &ast.SelectorExpr{
//     X: &ast.Ident{Name: "values"},
//     Sel: &ast.SelectorExpr{
//         X: &ast.Ident{Name: "api"},
//         Sel: &ast.Ident{Name: "image"}
//     }
// }

// Serialize syntax to output CUE
imageBytes, _ := format.Node(imageSyntax)
// imageBytes = "values.api.image" (as text, but represents reference)
```

### Output from Flattener

```cue
// Written to Module (IR)
container: {
    image: values.api.image  // Reference preserved as-is
}
```

---

## Comparison: Different Value Types

```cue
components: {
    api: {
        // CONCRETE VALUE
        name: "api-service"
        //    ^^^^^^^^^^^^
        //    AST: BasicLit{Value: "api-service"}
        //    Preserved as: "api-service"

        // SIMPLE REFERENCE
        image: values.api.image
        //     ^^^^^^^^^^^^^^^^
        //     AST: SelectorExpr{...}
        //     Preserved as: values.api.image

        // CONDITIONAL REFERENCE
        if values.api.enabled {
            //  ^^^^^^^^^^^^^^^^^
            //  AST: IfClause{Condition: SelectorExpr{...}, Body: ...}
            //  Preserved as: if values.api.enabled { ... }
            replicas: {count: 3}
        }

        // STRING INTERPOLATION
        fullImage: "\(values.registry)/\(values.api.image)"
        //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        //         AST: Interpolation{Parts: [SelectorExpr, Lit, SelectorExpr]}
        //         Preserved as: "\(values.registry)/\(values.api.image)"

        // COMPUTATION
        timeout: values.api.baseTimeout * 2
        //       ^^^^^^^^^^^^^^^^^^^^^^^^^^
        //       AST: BinaryExpr{Op: MUL, X: SelectorExpr, Y: BasicLit}
        //       Preserved as: values.api.baseTimeout * 2

        // DEFAULT VALUE
        port: values.api.port | *8080
        //    ^^^^^^^^^^^^^^^^^^^^^^^
        //    AST: BinaryExpr{Op: OR, X: SelectorExpr, Y: BasicLit}
        //    Preserved as: values.api.port | *8080
    }
}
```

**All of these are preserved through flattening!**

---

## Error Cases (What Happens If...)

### 1. Reference to Undefined Value

**Module (IR)**:

```cue
container: {
    image: values.api.image  // Reference exists
}
values: {
    // api field not defined!
}
```

**Result**: Module (IR) is still valid (reference is well-formed).

**ModuleRelease**:

```cue
module: <Module IR above>
values: {
    // Still no api field
}
```

**Error**: `cue export` fails with:

```
container.image: undefined field: api
```

### 2. Value Doesn't Match Constraint

**Module (IR)**:

```cue
container: {
    image: values.api.image
}
values: {
    api: {
        image!: string & =~"^[a-z]+:[a-z0-9.]+$"  // Constraint
    }
}
```

**ModuleRelease**:

```cue
module: <Module IR above>
values: {
    api: {
        image: "INVALID_IMAGE"  // Uppercase not allowed by regex
    }
}
```

**Error**: `cue vet` fails with:

```
values.api.image: invalid value "INVALID_IMAGE" (does not match =~"^[a-z]+:[a-z0-9.]+$")
```

### 3. Missing Required Value

**Module (IR)**:

```cue
values: {
    api: {
        image!: string  // Required (!)
    }
}
```

**ModuleRelease**:

```cue
module: <Module IR above>
values: {
    api: {
        // image not provided
    }
}
```

**Error**: `cue export` fails with:

```
values.api.image: field is required but not present
```

---

## Summary Table

| Aspect | ModuleDefinition | Module (IR) | ModuleRelease |
|--------|------------------|-------------|---------------|
| **Value references** | Present as CUE paths | **Preserved** as CUE paths | **Resolved** to concrete |
| **Constraints** | Present in values schema | **Preserved** in values schema | **Validated** against concrete values |
| **Composites** | Present | **Removed** | N/A |
| **Primitive schemas** | Referenced | **Inlined** | Inlined |
| **Validation** | Structure only | Structure + constraints | **Full validation** |
| **Ready for export** | ❌ No (composites) | ❌ No (references) | ✅ **Yes** (all concrete) |

---

## Code Snippet: The Magic Line

```go
// This single line preserves value references:
syntaxNode := fieldValue.Syntax(
    cue.Docs(true),
    cue.Attributes(true),
    cue.Optional(true),
    cue.Concrete(false),  // ← KEY: Don't require concrete values
)

// Serialize to output (preserves references):
outputBytes, _ := format.Node(syntaxNode)
```

Without `cue.Concrete(false)`, the flattener would error on any reference because they're not concrete yet. With it, we preserve the syntax tree as-is.

---

## Analogy: Variable References in Compilers

```
High-Level Language (TypeScript):
    const image = config.api.image;
    //            ^^^^^^^^^^^^^^^^ variable reference

Intermediate Representation (IR):
    LOAD config
    LOAD config.api
    LOAD config.api.image
    STORE image
    //    References preserved as load instructions

Machine Code (with concrete values):
    MOV eax, [config+8+16]  ; Resolved to memory address
```

OPM's flattening is like going from TypeScript to IR:

- **ModuleDefinition** = TypeScript (high-level abstractions)
- **Module (IR)** = IR (references preserved, composites removed)
- **ModuleRelease** = Machine code (concrete memory addresses)

The IR doesn't evaluate variable references - it just preserves them for later resolution.
