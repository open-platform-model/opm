# Advanced Template

**Level:** Advanced
**Complexity:** Multi-file organization
**Use Case:** Complex applications, large teams, platform engineering

## Overview

The Advanced template provides a sophisticated multi-file structure for organizing complex applications. This template demonstrates best practices for large-scale OPM projects with multiple components, scopes, and shared configuration patterns.

## Structure

```
advanced/
├── module.cue       # Main ModuleDefinition (aggregates everything)
├── components.cue   # Component definitions with template imports
├── values.cue       # Complex value schema
└── scopes.cue       # Scope definitions with template imports
```

## When to Use

- **Large applications** - 10+ components
- **Complex architectures** - Multi-tier, microservices
- **Platform teams** - Using external template libraries
- **Shared configuration** - Reusing components and scopes from template modules
- **Team collaboration** - Different teams owning different areas
- **Enterprise projects** - Complex value schemas with nested configuration

## Getting Started

### 1. Initialize

```bash
opm mod init my-platform --template advanced
cd my-platform
```

### 2. Review components.cue

The advanced template uses external template imports to reference pre-defined component patterns:

```cue
package advanced

import (
    components "template.opm.dev/components"
)

#components: {
    // Reference external template and customize
    web: components._web & {
        container: {
            image: #values.web.image
            ports: http: {
                targetPort: #values.web.port
                protocol:   "TCP"
            }
            resources: {
                limits: {
                    cpu:    #values.web.resources.cpu
                    memory: #values.web.resources.memory
                }
            }
        }
        replicas: #values.web.replicas
    }

    // More components: api, worker, db
}
```

**Key Pattern**: Components reference external templates (like `components._web`) and unify with concrete specs that reference the value schema.

### 3. Customize values.cue

The advanced template includes a complex value schema with nested configuration:

```cue
#values: {
    web: {
        image!:    string
        replicas?: int & >=1 & <=20 | *3
        port?:     int & >0 & <65536 | *80

        resources?: {
            cpu?:    string | *"100m"
            memory?: string | *"128Mi"
        }
    }

    api: {
        image!:    string
        replicas?: int & >=1 & <=50 | *5
        port?:     int & >0 & <65536 | *8080

        resources?: {
            cpu?:    string | *"500m"
            memory?: string | *"512Mi"
        }

        rateLimit?: {
            enabled?:        bool | *true
            requestsPerMin?: int & >0 | *1000
        }
    }

    db: {
        image!:      string
        volumeSize!: string

        backup?: {
            enabled?:   bool | *true
            schedule?:  string | *"0 2 * * *"  // Daily at 2 AM
            retention?: int & >0 | *7           // Days
        }

        resources?: {
            cpu?:    string | *"1000m"
            memory?: string | *"2Gi"
        }
    }
}
```

**Key Features**: Nested configuration for resources, rate limiting, job queues, and backup policies.

### 4. Review scopes.cue

The advanced template uses external scope imports for pre-defined scope patterns:

```cue
package advanced

import (
    scopes "template.opm.dev/scopes"
)

#scopes: {
    // Reference external scope templates
    frontend: scopes._api
    backend:  scopes._backend
}
```

**Key Pattern**: Scopes reference external templates from shared libraries, providing consistent scope definitions across modules.

### 5. Build

```bash
# Flatten to optimized Module
opm mod build . --output ./dist/my-platform.module.cue

# Or render directly to Kubernetes
opm mod render . --platform kubernetes --output ./k8s
```

## Key Concepts

### File Organization

All files in the same package are automatically unified by CUE:

- **module.cue** - Main entry point with metadata
- **components.cue** - Component definitions using external template imports
- **values.cue** - Complex value schema with nested configuration
- **scopes.cue** - Scope definitions using external template imports

**No imports needed between files in the same package!**

### External Template Imports

The advanced template demonstrates importing and extending external templates:

```cue
import (
    components "template.opm.dev/components"
    scopes "template.opm.dev/scopes"
)
```

This allows reusing pre-defined patterns while customizing them with concrete values.

### Hidden Fields (_prefix)

External templates use hidden fields (prefixed with `_`) for reusable patterns:

```cue
// External template defines:
_web: {
    units_workload.#Container
    traits_workload.#Replicas
    // ... base configuration
}

// Your components.cue references and extends:
web: components._web & {
    container: {
        image: #values.web.image  // Add concrete values
    }
}
```

Hidden fields don't appear in final output but can be referenced and extended.

### Component Composition Pattern

The advanced template demonstrates a powerful composition pattern:

1. **Import external templates**: `import components "template.opm.dev/components"`
2. **Reference template**: `web: components._web & { ... }`
3. **Add concrete specs**: Override/extend with value references
4. **Reference value schema**: Use `#values.web.image`, `#values.web.replicas`, etc.

This pattern allows:
- Reusing standardized component definitions
- Customizing with environment-specific values
- Maintaining consistency across modules

### Value Schema Patterns

The advanced template shows sophisticated value schema patterns:

**Nested configuration:**
```cue
resources?: {
    cpu?:    string | *"100m"
    memory?: string | *"128Mi"
}
```

**Component-specific settings:**
```cue
rateLimit?: {
    enabled?:        bool | *true
    requestsPerMin?: int & >0 | *1000
}
```

**Backup policies:**
```cue
backup?: {
    enabled?:   bool | *true
    schedule?:  string | *"0 2 * * *"
    retention?: int & >0 | *7
}
```

### Scopes

Scopes reference external templates for consistent scope definitions:

```cue
import (
    scopes "template.opm.dev/scopes"
)

#scopes: {
    frontend: scopes._api      // Public-facing scope
    backend:  scopes._backend  // Internal services scope
}
```

This pattern ensures consistent scope definitions across modules and teams.

## Customization Examples

### Add New Component

In [components.cue](components.cue):

```cue
#components: {
    web:    { ... }
    api:    { ... }
    worker: { ... }
    db:     { ... }

    // Add new cache component
    cache: components._cache & {
        container: {
            image: #values.cache.image
            ports: redis: {
                targetPort: 6379
                protocol:   "TCP"
            }
        }
    }
}
```

In [values.cue](values.cue):

```cue
#values: {
    web:    { ... }
    api:    { ... }
    worker: { ... }
    db:     { ... }

    // Add cache values
    cache: {
        image!: string
    }
}
```

### Extend Value Schema

Add more nested configuration to existing components:

```cue
api: {
    image!: string

    // Add monitoring configuration
    monitoring?: {
        enabled?:      bool | *true
        metricsPort?:  int | *9090
        scrapeInterval?: string | *"30s"
    }
}
```

### Add Custom Scope

In [scopes.cue](scopes.cue):

```cue
#scopes: {
    frontend: scopes._api
    backend:  scopes._backend

    // Add custom data tier scope
    data: scopes._data
}
```

## Migration Paths

### From Simple → Standard → Advanced

**Simple → Standard**: Separate values into separate file
**Standard → Advanced**: Add external template imports and scopes

Starting from standard template:

1. Add external template imports to `components.cue`
2. Update component definitions to reference external templates
3. Add `scopes.cue` with external scope imports
4. Keep same package name - CUE will unify everything

### Growing the Advanced Template

As your application grows:

1. **More external templates**: Import additional template libraries
2. **Split files**: Organize components by tier, function, or team
3. **Complex value schemas**: Add more nested configuration
4. **Additional scopes**: Define more fine-grained boundaries
5. **Custom patterns**: Create local helper files if needed

## Benefits of Advanced Organization

### External Template Reuse

- Import standardized component and scope definitions
- Consistent patterns across multiple modules and teams
- Updates to template libraries benefit all consumers
- Reduce duplication and maintenance burden

### Complex Value Schemas

- Nested configuration for sophisticated applications
- Component-specific settings (rate limiting, job queues, backups)
- Rich constraints and validation
- Self-documenting configuration

### Scalability

- Multi-file organization for large applications
- Clear structure for complex architectures
- Easy to extend with new components and scopes

### Team Collaboration

- Platform teams manage external templates
- Application teams customize with values
- Clear boundaries between template and configuration
- Reduced merge conflicts

## Examples Included

The template includes working examples for:

- **4 components** - web, api, worker, database
  - External template references (`components._web`, `components._api`, etc.)
  - Concrete specs with value references
  - Resource limits and port configurations
- **2 scopes** - frontend and backend tiers
  - External scope imports (`scopes._api`, `scopes._backend`)
- **Complex value schemas**
  - Nested resources (cpu, memory)
  - API rate limiting configuration
  - Worker job queue settings
  - Database backup policies

## Best Practices

### 1. Use External Templates Consistently

Import and reference external templates for all components:

```cue
import (
    components "template.opm.dev/components"
)

web: components._web & {
    container: {
        image: #values.web.image  // Override with values
    }
}
```

Benefits: Consistency, reduced duplication, easier updates

### 2. Separate Value Schema from Component Definitions

Keep all value constraints in [values.cue](values.cue):
- Makes configuration boundaries clear
- Easier to review and validate
- Self-documenting configuration options

### 3. Use Nested Value Schemas

Organize related configuration together:

```cue
api: {
    image!: string

    rateLimit?: {
        enabled?:        bool | *true
        requestsPerMin?: int & >0 | *1000
    }
}
```

### 4. Leverage Scopes for Organization

Use scopes to define boundaries and apply policies:
- Network boundaries (frontend vs backend)
- Security policies (public vs internal)
- Deployment groups (by tier or function)

### 5. Keep module.cue Simple

The main file should only declare ModuleDefinition and metadata. Let CUE unify everything from other files automatically.

## Learn More

- [CLI Specification](../../../V1ALPHA1_SPECS/CLI_SPEC.md#directory-structure--templates)
- [Module Definition Specification](../../../V1ALPHA1_SPECS/MODULE_DEFINITION.md) (coming soon)
- [Scope Definition Specification](../../../V1ALPHA1_SPECS/SCOPE_DEFINITION.md) (coming soon)
- [OPM Documentation](../../../README.md)
