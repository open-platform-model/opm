# Simple Template

**Level:** Beginner
**Complexity:** Single file
**Use Case:** Learning, quick prototypes, demos

## Overview

The Simple template provides everything in a single `module.cue` file - perfect for getting started with OPM. This template includes the ModuleDefinition, components with concrete specifications, and value schema all inline.

## Structure

```
simple/
└── module.cue    # Everything in one file
```

## When to Use

- **Learning OPM** - Easiest way to understand OPM concepts
- **Simple applications** - 1-3 components
- **Quick prototypes** - Fast iteration during development
- **Demos and examples** - Clear, self-contained examples

## Getting Started

### 1. Initialize

```bash
opm mod init my-app --template simple
cd my-app
```

### 2. Customize module.cue

The template includes example components that you can customize:

**Web server component:**
```cue
web: {
    units_workload.#Container
    traits_workload.#Replicas

    spec: {
        container: {
            name:  #values.web.image
            image: "nginx:latest"  // Change to your image
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
```

**Database component:**
```cue
db: {
    units_workload.#Container
    units_storage.#Volumes

    spec: {
        container: {
            name:  #values.db.image
            image: "postgres:latest"  // Change to your database
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
```

### 3. Update Values

Customize the value schema for your needs:

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

### 4. Build

```bash
# Flatten to optimized Module
opm mod build . --output ./dist/my-app.module.cue

# Or render directly to Kubernetes
opm mod render . --platform kubernetes --output ./k8s
```

## Key Concepts

### Component Structure

Components in OPM are composed from Units and Traits:

**Units** define what exists:
- `units_workload.#Container` - Container workload
- `units_storage.#Volumes` - Persistent storage

**Traits** define how it behaves:
- `traits_workload.#Replicas` - Scaling behavior

### Spec Block

The `spec:` block provides concrete configuration that references values:

```cue
spec: {
    container: {
        image: "nginx:latest"        // Concrete value
        name:  #values.web.image     // Reference to value schema
    }
}
```

### Value References

Use `#values` to reference the value schema from within component specs:

```cue
replicas: #values.web.replicas
size:     #values.db.volumeSize
```

This creates a connection between the component spec and the values that will be provided at deployment.

### Value Schema

The `#values` field defines **constraints**, not concrete values:

- `image!: string` - Required field
- `replicas?: int & >=1 & <=10 | *3` - Optional with default (3) and constraints

Concrete values are provided at deployment time (ModuleRelease).

## Customization Examples

### Change the Web Server Image

```cue
container: {
    image: "nginx:alpine"  // Use Alpine-based nginx
}
```

### Add Environment Variables

```cue
container: {
    image: "myapp:latest"
    env: {
        DATABASE_URL: "postgres://db:5432/myapp"
        ENVIRONMENT:  "production"
    }
}
```

### Adjust Resource Limits

```cue
container: {
    image: "myapp:latest"
    resources: {
        limits: {
            cpu:    "500m"
            memory: "512Mi"
        }
    }
}
```

## Migration Path

As your application grows, you can migrate to more complex templates:

### Simple → Standard

1. Create `components.cue` and `values.cue`
2. Move `#components` to `components.cue`
3. Move `#values` to `values.cue`
4. Keep same package name
5. Update `module.cue` to reference these files

### Simple → Advanced

1. Follow Simple → Standard migration
2. Add `scopes.cue` for scope definitions
3. Create `definitions/` directory for shared patterns
4. Organize components by tier or function

## Examples Included

The template includes working examples for:
- **Web server** - Container with replicas and port configuration
- **Database** - Container with persistent volume storage
- **Value schema** - Required fields and optional with defaults
- **Value references** - Connecting specs to value schema

## Learn More

- [CLI Specification](../../../V1ALPHA1_SPECS/CLI_SPEC.md#directory-structure--templates)
- [Module Definition Specification](../../../V1ALPHA1_SPECS/MODULE_DEFINITION.md) (coming soon)
- [OPM Documentation](../../../README.md)
