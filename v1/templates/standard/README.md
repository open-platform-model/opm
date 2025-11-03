# Standard Template

**Level:** Intermediate
**Complexity:** Three files (module + components + values)
**Use Case:** Most applications, team projects

## Overview

The Standard template separates ModuleDefinition, components, and value schema into three files. This separation provides better organization and is ideal for team projects where components and values may have different owners or update frequencies.

## Structure

```
standard/
├── module.cue        # ModuleDefinition (main entry point)
├── components.cue    # Component definitions
└── values.cue        # Value schema (separate)
```

## When to Use

- **Medium applications** - 3-10 components
- **Team projects** - Clear separation of concerns
- **Shared values** - When values need to be reused across modules
- **Frequent updates** - When components and values change independently

## Getting Started

### 1. Initialize

```bash
opm mod init my-app --template standard
cd my-app
```

### 2. Review module.cue

The main ModuleDefinition aggregates everything:

```cue
package standard

import (
    core "opm.dev/core@v1"
)

core.#ModuleDefinition

metadata: {
    apiVersion:  "opm.dev/modules/core@v1"
    name:        "StandardApp"
    version:     "1.0.0"
    description: "Standard web application with database"
}

// Components are automatically unified from components.cue
// Values are automatically unified from values.cue
```

### 3. Customize components.cue

Uncomment and customize the example components:

```cue
#components: {
    web: {
        units_workload.#Container
        traits_workload.#Replicas

        spec: {
            container: {
                name:  #values.web.image
                image: "nginx:latest"
                ports: {
                    http: {
                        name:       "http"
                        targetPort: 80
                    }
                }
            }
            replicas: #values.web.replicas
        }
    }

    db: {
        units_workload.#Container
        units_storage.#Volumes

        spec: {
            container: {
                name:  #values.db.image
                image: "postgres:latest"
                ports: {
                    dbPort: {
                        name:       "db-port"
                        targetPort: 5432
                    }
                }
            }
            volumes: {
                dataVolume: {
                    name: "data-volume"
                    persistentClaim: {
                        size:         #values.db.volumeSize
                        accessMode:   "ReadWriteOnce"
                        storageClass: "standard"
                    }
                }
            }
        }
    }
}
```

### 4. Customize values.cue

Update the value schema for your needs:

```cue
#values: {
    web: {
        image!:    string
        replicas?: int & >=1 & <=10 | *3
    }
    db: {
        image!:      string
        volumeSize!: string
    }
}
```

### 5. Build

```bash
# Flatten to optimized Module
opm mod build . --output ./dist/my-app.module.cue

# Or render directly to Kubernetes
opm mod render . --platform kubernetes --output ./k8s
```

## Key Concepts

### File Organization

CUE automatically unifies all `.cue` files in the same package:

- **module.cue** - Main entry point with metadata
- **components.cue** - Component definitions with specs
- **values.cue** - Value schema and constraints
- No imports needed between files in the same package!

### Component Composition

Components use Units and Traits with concrete specs:

```cue
web: {
    // Units and Traits
    units_workload.#Container
    traits_workload.#Replicas

    // Concrete specification
    spec: {
        container: { ... }
        replicas: #values.web.replicas
    }
}
```

### Value References

Components reference the value schema using `#values`:

```cue
spec: {
    container: {
        name:  #values.web.image      // Reference value schema
        image: "nginx:latest"          // Concrete default
    }
    replicas: #values.web.replicas
}
```

### Value Schema Patterns

The value schema shows several useful patterns:

**Required fields:**
```cue
image!: string
```

**Optional with default:**
```cue
replicas?: int & >=1 & <=10 | *3
```

**Optional with constraints:**
```cue
port?: int & >0 & <65536 | *8080
```

## Customization Examples

### Add Health Checks

In `components.cue`:

```cue
api: {
    units_workload.#Container
    traits_workload.#Replicas
    traits_workload.#HealthCheck  // Add health checking

    spec: {
        container: { ... }
        replicas: #values.api.replicas
        healthCheck: {
            liveness: {
                httpGet: {
                    path: "/health"
                    port: 8080
                }
            }
        }
    }
}
```

### Add Resource Limits

In `components.cue`:

```cue
container: {
    image: "myapp:latest"
    resources: {
        limits: {
            cpu:    "500m"
            memory: "512Mi"
        }
        requests: {
            cpu:    "250m"
            memory: "256Mi"
        }
    }
}
```

In `values.cue`:

```cue
api: {
    image!: string
    resources?: {
        cpu?:    string | *"500m"
        memory?: string | *"512Mi"
    }
}
```

### Add New Component

In `components.cue`:

```cue
#components: {
    web: { ... }
    db:  { ... }

    // New cache component
    cache: {
        units_workload.#Container

        spec: {
            container: {
                name:  #values.cache.image
                image: "redis:latest"
                ports: {
                    redis: {
                        targetPort: 6379
                    }
                }
            }
        }
    }
}
```

In `values.cue`:

```cue
#values: {
    web:   { ... }
    db:    { ... }
    cache: {
        image!: string
    }
}
```

## Migration Paths

### From Simple → Standard

You're already here! The Standard template separates Simple's single file into three files.

### Standard → Advanced

When your application grows:

1. Add `scopes.cue` for scope definitions
2. Create `definitions/` directory for shared patterns
3. Split `components.cue` by tier (frontend, backend, data)
4. Split `values.cue` by component category
5. Keep same package name - CUE automatically unifies

## Benefits of Separation

### Clear Ownership

- Platform team manages `module.cue` and `components.cue`
- DevOps team manages `values.cue`
- Different teams can own different component groups

### Version Control

- Component changes in separate commits from value schema changes
- Easier to track what changed and why
- Reduced merge conflicts

### Reusability

- Value schemas can be shared across multiple modules
- Components can reference external component libraries
- Clear boundaries between definition and configuration

### Collaboration

- Multiple team members can work on different files simultaneously
- Each file has a single, clear responsibility
- Easier code reviews

## File Responsibilities

### module.cue
- Declares `core.#ModuleDefinition`
- Sets module metadata (name, version, description)
- Aggregates components and values from other files

### components.cue
- Defines all components
- Specifies Units and Traits composition
- Provides concrete specs with value references
- Organizes components logically

### values.cue
- Defines value schema (constraints)
- Specifies required vs optional fields
- Sets defaults and validation rules
- Documents configuration options

## Examples Included

The template includes working examples for:
- **Web server** - Container with replicas, ports, and value references
- **Database** - Container with persistent volumes and configuration
- **Value schema** - Required fields, optionals with defaults
- **File organization** - Clean separation of concerns

## Best Practices

### 1. Keep module.cue Simple

The main file should just declare the ModuleDefinition and metadata. Let CUE unify the rest.

### 2. Organize Components by Function

Group related components together in `components.cue`:
```cue
#components: {
    // Frontend
    web: { ... }
    cdn: { ... }

    // Backend
    api:    { ... }
    worker: { ... }

    // Data
    db:    { ... }
    cache: { ... }
}
```

### 3. Use Descriptive Value Names

Make value schema self-documenting:
```cue
#values: {
    web: {
        containerImage!:     string  // Clear what this is
        replicaCount?:       int     // Descriptive name
        healthCheckPath?:    string  // Easy to understand
    }
}
```

### 4. Reference Values from Specs

Always reference `#values` in your component specs:
```cue
spec: {
    container: {
        image: #values.web.containerImage  // Reference schema
    }
}
```

## Learn More

- [CLI Specification](../../../V1ALPHA1_SPECS/CLI_SPEC.md#directory-structure--templates)
- [Module Definition Specification](../../../V1ALPHA1_SPECS/MODULE_DEFINITION.md) (coming soon)
- [OPM Documentation](../../../README.md)
