# OPM Module Directory Structure & Templates Guide

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-03

---

## Overview

OPM uses a **three-layer architecture** with distinct file structure patterns for each layer:

1. **Authoring Layer** - Flexible structure (ModuleDefinition/BundleDefinition)
2. **Compiled Layer** - Single file (Module/Bundle, CLI-generated)
3. **Deployment Layer** - Single file (ModuleRelease/BundleRelease, user-created)

**Key Principle:** The `module_definition.cue` file is THE foundation for ModuleDefinitions, and `bundle.cue` is THE foundation for BundleDefinitions. Everything else revolves around these core files and is unified by CUE.

---

## Layer 1: Authoring (ModuleDefinition / BundleDefinition)

### ModuleDefinition Structure

#### Core File (Required):

- **`module_definition.cue`** - THE foundation file that must declare `core.#ModuleDefinition`

#### Optional Files:

- `values.cue` - Value schema (can be inline in module_definition.cue or separate)
- `*.cue` - Any additional CUE files (unified by CUE's package system)

#### File Discovery:

The CLI looks for `module_definition.cue` in the following order:

1. Explicit file path: `opm mod render ./path/to/module_definition.cue`
2. Current directory: `opm mod render .` (searches for `./module_definition.cue`)
3. Subdirectory: `opm mod render ./my-app` (searches for `./my-app/module_definition.cue`)

#### Directory Structure Patterns:

OPM supports **flexible directory structures** - you can organize files however makes sense for your project. CUE's unification system automatically combines all `.cue` files in the same package.

##### Pattern 1: Simple (Beginner)

Everything in one file.

```text
my-app/
├── module_definition.cue          # ModuleDefinition + components + values
└── cue.mod/
    └── module_definition.cue      # CUE module config (auto-generated)
```

**When to use:**

- Learning OPM
- Simple applications (1-3 components)
- Quick prototypes
- Demos and examples

##### Pattern 2: Standard (Intermediate)

Separate components and values for better organization.

```text
my-app/
├── module_definition.cue          # ModuleDefinition (main entry point)
├── components.cue      # Component definitions
├── values.cue          # Value schema
└── cue.mod/
    └── module_definition.cue
```

**When to use:**

- Medium applications (3-10 components)
- Team projects with clear separation of concerns
- When values need to be shared/reused
- When components and values have different owners or update frequencies

##### Pattern 3: Advanced (Complex Applications)

Multi-file organization with external template imports.

```text
my-platform/
├── module_definition.cue          # ModuleDefinition (aggregates everything)
├── components.cue      # Component definitions with template imports
├── values.cue          # Complex value schema
├── scopes.cue          # Scope definitions with template imports
└── cue.mod/
    └── module_definition.cue
```

**When to use:**

- Large applications (10+ components)
- Complex architectures with external template dependencies
- Platform teams using template libraries
- Enterprise projects with nested value schemas

##### Mixing Patterns:

You can mix these patterns freely! For example:

```text
my-mixed-app/
├── module_definition.cue          # Main definition (simple)
├── components/         # Some components hierarchical
│   ├── api.cue
│   └── worker.cue
├── database.cue        # Other components flat
└── values/             # Values hierarchical
    ├── api-values.cue
    └── db-values.cue
```

CUE automatically unifies all files in the same package, regardless of directory structure.

### BundleDefinition Structure

#### Core File (Required):

- **`bundle.cue`** - THE foundation file that must declare `core.#BundleDefinition`

#### Optional Files:

- `values.cue` - Bundle-level value schema (can be inline or separate)
- `*.cue` - Any additional CUE files

#### File Discovery:

Same pattern as ModuleDefinition, but looks for `bundle.cue`:

1. Explicit: `opm bundle build ./path/to/bundle.cue`
2. Current dir: `opm bundle build .` (searches for `./bundle.cue`)
3. Subdirectory: `opm bundle build ./platform` (searches for `./platform/bundle.cue`)

#### Directory Structure Pattern:

```text
platform-bundle/
├── bundle.cue          # BundleDefinition with inline modules
├── values.cue          # Bundle-level value schema (optional)
└── cue.mod/
    └── module_definition.cue
```

#### Example `bundle.cue`:

```cue
package platform

import (
    core "opm.dev/core@v1"
)

core.#BundleDefinition

metadata: {
    apiVersion: "platform.io/bundles@v1"
    name:       "MyPlatform"
    version:    "1.0.0"
}

modulesDefinitions: {
    observability: core.#ModuleDefinition & {
        metadata: name: "observability"
        #components: {...}
    }

    security: core.#ModuleDefinition & {
        metadata: name: "security"
        #components: {...}
    }
}

values: {...}
```

---

## Layer 2: Compiled (Module / Bundle)

**Generated by CLI - Single File, Pure CUE Only**

When you run `opm mod render` or `opm bundle build`, the CLI:

1. Loads all `.cue` files in the package
2. Unifies them into a single ModuleDefinition/BundleDefinition
3. Flattens Blueprints into Resources + Traits
4. Outputs an optimized Module/Bundle (single file, **pure CUE only**)

**Important:** This step does **not** generate platform-specific resources. Use `opm mod render` or `opm bundle render` for that.

### Structure:

```text
dist/
└── my-app.module_definition.cue      # Single file, pure CUE (CLI-generated)
```

or

```text
dist/
└── platform.bundle.cue    # Single file, pure CUE (CLI-generated)
```

### Characteristics:

- **Single file** - Always one file per module/bundle
- **Pure CUE** - No platform-specific output (YAML/JSON)
- **Flattened** - Blueprints expanded to Units + Traits
- **Optimized** - For fast rendering and reduced memory usage
- **Not for manual editing** - Generated artifact, intermediate representation
- **Performance** - 50-80% faster rendering, 40-60% less memory

### Performance Benefits:

| Operation | ModuleDefinition | Module (Flattened) | Improvement |
|-----------|------------------|-------------------|-------------|
| First flatten | 5-10s | - | - |
| Rendering | 2-3s | 0.5-1s | 50-80% faster |
| Memory usage | 100% | 40-60% | 40-60% reduction |

### Build Commands:

```bash
# Flatten ModuleDefinition to optimized Module (pure CUE)
opm mod render ./my-app --output ./dist/my-app.module_definition.cue

# Flatten BundleDefinition to optimized Bundle (pure CUE)
opm bundle build ./platform --output ./dist/platform.bundle.cue
```

### Rendering to Platform Resources:

```bash
# From Module to Kubernetes YAML
opm mod render ./dist/my-app.module_definition.cue --platform kubernetes --output ./k8s

# From Bundle to Kubernetes YAML
opm bundle render ./dist/platform.bundle.cue --platform kubernetes --output ./k8s
```

---

## Layer 3: Deployment (ModuleRelease / BundleRelease)

**Created by End Users - Single File**

A deployment manifest that combines a Module/Bundle reference with concrete values.

### Structure:

```text
releases/
└── my-app-production.release.cue    # Single file, user-created
```

or

```text
releases/
└── platform-team-a.bundle-release.cue    # Single file, user-created
```

### Example ModuleRelease:

```cue
package deployment

import (
    core "opm.dev/core@v1"
)

core.#ModuleRelease

metadata: {
    name:      "my-app-prod"
    namespace: "production"
}

module: {
    // Reference to compiled Module (from OCI registry or local)
    // Can be embedded or referenced
}

values: {
    web: {
        image:    "myapp:v1.2.3"
        replicas: 5
    }
    db: {
        image:      "postgres:14"
        volumeSize: "100Gi"
    }
}
```

### Deployment Commands:

```bash
# Create ModuleRelease file manually
cat > ./releases/my-app-prod.release.cue << 'EOF'
package myapp

import core "opm.dev/core@v1"

core.#ModuleRelease & {
    metadata: {
        name: "my-app-prod"
        namespace: "production"
    }
    spec: {
        module: "./dist/my-app.module_definition.cue"  // Reference to built Module
        values: {
            replicas: 5
            image: "myapp:v1.2.3"
        }
    }
}
EOF

# Render resources from ModuleRelease
opm mod render ./releases/my-app-prod.release.cue \
  --platform kubernetes \
  --output ./k8s-manifests
```

---

## Template System

Templates provide starting points for ModuleDefinitions and BundleDefinitions. Templates are distributed as OCI artifacts with embedded fallback for official templates.

### Template Distribution:

**OCI Registry (Primary):**
- Templates are published as separate CUE modules to OCI registry
- Each template has its own module path: `opm.dev/templates/{name}@v1`
- Versioned using semantic versioning: `opm.dev/templates/simple:v1.0.0-alpha.1`
- Cached locally at `~/.cache/opm/templates/` with TTL-based expiration
- Supports custom templates from any OCI registry

**Embedded Fallback (Official Templates Only):**
- Official templates (simple, standard, advanced) are embedded in CLI binary
- Used when OCI registry is unavailable (offline mode)
- Always match CLI version
- Custom templates require network access

**Template Reference Formats:**

OCI references use **colon** (`:`) for versions:
```
opm.dev/templates/simple:v1.0.0-alpha.1
oci://localhost:5000/custom-template:v2.0.0
```

CUE module definitions use **at sign** (`@`) for major versions:
```cue
module: "opm.dev/templates/simple@v1"
```

**Template Structure:**

Each template is a CUE module with the following structure:
```
template-name/
├── cue.mod/module.cue        # CUE module definition
├── template/
│   └── template.cue          # Template metadata (removed during init)
├── module_definition.cue      # ModuleDefinition or template structure
└── README.md                 # Template-specific documentation
```

**Important:** The `template/` directory is removed during `opm mod init` to avoid polluting the user's module. It contains metadata used by CLI commands (`opm mod template list`, `opm mod template show`) but not needed in the final module.

### Available Templates:

#### 1. Simple Template (`opm.dev/templates/simple`)

Single file with everything inline.

```text
simple/
├── cue.mod/module.cue       # CUE module definition
├── template/
│   └── template.cue         # Template metadata (removed during init)
├── module_definition.cue     # ModuleDefinition + components + values
└── README.md
```

**Use case:** Beginners, quick starts, demos

**Initialize:**

```bash
# Using short name (resolves to official template)
opm mod init my-app --template simple

# Using full OCI reference with version
opm mod init my-app --template opm.dev/templates/simple:v1.0.0-alpha.1
```

#### 2. Standard Template (`opm.dev/templates/standard`)

Separated module, components, and values files.

```text
standard/
├── cue.mod/module.cue       # CUE module definition
├── template/
│   └── template.cue         # Template metadata (removed during init)
├── module_definition.cue     # ModuleDefinition (main entry point)
├── components.cue            # Component definitions
├── values.cue                # Value schema
└── README.md
```

**Use case:** Most applications, team projects with clear separation of concerns

**Initialize:**

```bash
# Using short name
opm mod init my-app --template standard

# Using full OCI reference with version
opm mod init my-app --template opm.dev/templates/standard:v1.0.0-alpha.1
```

**Example `module_definition.cue`:**

```cue
package standard

import (
    core "opm.dev/core@v1"
    workload_units "opm.dev/resources/workload@v1"
    storage_units "opm.dev/resources/storage@v1"
    workload_traits "opm.dev/traits/workload@v1"
)

core.#ModuleDefinition

metadata: {
    apiVersion:  "opm.dev/modules/core@v1"
    name:        "MyApp"
    version:     "1.0.0"
    description: "Example multi-tier application"
}

#components: {
    web: {
        metadata: name: "web-server"

        // Use helper shortcuts (CUE unifies these)
        workload_units.#Container
        workload_traits.#Replicas
    }

    db: {
        metadata: name: "database"

        workload_units.#Container
        storage_units.#Volumes
    }
}
```

**Example `values.cue`:**

```cue
package standard

// Value schema: Constraints only, NO concrete values
#values: {
    web: {
        image!:    string                // Required
        replicas?: int & >=1 & <=10 | *3 // Optional with default
    }
    db: {
        image!:      string // Required
        volumeSize!: string // Required
    }
}
```

#### 3. Advanced Template (`opm.dev/templates/advanced`)

Multi-file organization with external template imports.

```text
advanced/
├── cue.mod/module.cue       # CUE module definition
├── template/
│   └── template.cue         # Template metadata (removed during init)
├── module_definition.cue     # ModuleDefinition (main entry point)
├── components.cue            # Component definitions with template imports
├── values.cue                # Complex value schema
├── scopes.cue                # Scope definitions with template imports
└── README.md
```

**Use case:** Complex applications, platform teams using external template libraries, enterprise projects with nested value schemas

**Initialize:**

```bash
# Using short name
opm mod init my-platform --template advanced

# Using full OCI reference with version
opm mod init my-platform --template opm.dev/templates/advanced:v1.0.0-alpha.1
```

#### 4. Platform Bundle Template (`v1/templates/platform-bundle/`)

Bundle with multiple modules.

```text
platform-bundle/
├── bundle.cue    # BundleDefinition with modules
└── values.cue    # Bundle-level value schema
```

**Use case:** Platform teams distributing complete stacks

**Initialize:**

```bash
opm bundle init my-platform --template platform-bundle
```

#### Custom Templates from OCI Registry

Templates can be published to and pulled from any OCI registry:

```bash
# Initialize from custom OCI registry template
opm mod init my-app --template oci://localhost:5000/custom-template:v2.0.0

# Initialize with specific version
opm mod init my-app --template oci://registry.io/myorg/webapp:v1.5.0

# Initialize bundle from OCI registry
opm bundle init platform --template oci://registry.io/platform/k8s-starter:v1.0.0
```

**Template Publishing:**

Templates are published using the template publishing workflow (see `templates/Taskfile.yml`):

```bash
# From templates directory
cd templates

# Validate template
task validate:simple

# Publish to OCI registry
task publish:simple VERSION=v1.0.0-alpha.1

# Or publish all templates
task publish:all VERSION=v1.0.0-alpha.1
```

**Creating Custom Templates:**

See [templates/README.md](../../templates/README.md) for complete guide on creating and publishing custom templates.

---

## Complete Module Definition Example

**Using the Standard Template Pattern:**

File: `v1/templates/standard/module_definition.cue`

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

// Note: Components are defined in components.cue
// CUE automatically unifies the #components field from that file

// Note: Value schema is defined in values.cue
// CUE automatically unifies the #values field from that file
```

File: `v1/templates/standard/components.cue`

```cue
package standard

import (
    workload_units "opm.dev/resources/workload@v1"
    storage_units "opm.dev/resources/storage@v1"
    workload_traits "opm.dev/traits/workload@v1"
)

#components: {
    web: {
        // Compose using helper shortcuts
        workload_units.#Container
        workload_traits.#Replicas

        // Concrete specification with value references
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
        workload_units.#Container
        storage_units.#Volumes

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

File: `v1/templates/standard/values.cue`

```cue
package standard

// Value schema defines CONSTRAINTS, not concrete values
// Concrete values are provided at deployment time (ModuleRelease)
#values: {
    web: {
        image!:    string                // Required field
        replicas?: int & >=1 & <=10 | *3 // Optional with default of 3
    }
    db: {
        image!:      string // Required
        volumeSize!: string // Required
    }
}
```

---

## Best Practices

### When to Inline vs. Separate `values.cue`

**Inline in `module_definition.cue` when:**

- Simple value schema (1-5 fields)
- Single component modules
- Learning/demo purposes
- Values rarely change

**Separate `values.cue` when:**

- Complex value schema (10+ fields)
- Values reused across multiple modules
- Team collaboration (separate ownership)
- Values updated frequently

### When to Add Additional Files

**Add additional `.cue` files when:**

- Components don't fit comfortably in one file (>200 lines)
- Different team members own different components
- Shared definitions need to be reused
- Clear separation of concerns improves readability

**Keep in mind:**

- CUE automatically unifies all files in the same package
- No imports needed for files in same package
- File organization is for human readability
- Structure doesn't affect CLI behavior

### Component Organization

**For large component sets, organize by category:**

```text
my-app/
├── module_definition.cue              # Main aggregation
├── components/
│   ├── workloads.cue      # Web, API, Worker components
│   ├── databases.cue      # Database components
│   └── services.cue       # Networking components
└── values/
    ├── workload-values.cue
    ├── database-values.cue
    └── shared-values.cue
```

**Common categories:**

- `workloads` - Deployable services
- `data` - Databases, caches, storage
- `network` - Ingress, service mesh, connectivity
- `config` - ConfigMaps, Secrets

### Importing Resources, Traits, and Blueprints

**Always import specific packages:**

```cue
// Good: Specific imports
import (
    workload_units "opm.dev/resources/workload@v1"
    storage_units "opm.dev/resources/storage@v1"
    workload_traits "opm.dev/traits/workload@v1"
)

// Bad: Avoid wildcards or unclear imports
import "opm.dev/units@v1"  // Too broad
```

**Use descriptive aliases:**

```cue
// Good: Clear what's being imported
workload_units "opm.dev/resources/workload@v1"
traits_scaling "opm.dev/traits/scaling@v1"

// Bad: Unclear aliases
uw "opm.dev/resources/workload@v1"
t "opm.dev/traits/scaling@v1"
```

### Helper Shortcuts Usage

**Components can be composed using helper shortcuts:**

```cue
#components: {
    api: {
        metadata: name: "api-server"

        // These helper shortcuts are automatically unified
        workload_units.#Container    // Adds container unit
        workload_traits.#Replicas    // Adds replicas trait
        workload_traits.#HealthCheck // Adds health check trait
    }
}
```

**Helper shortcuts are defined in resource/trait packages:**

```cue
// From units/workload/container.cue
#Container: close(core.#ComponentDefinition & {
    #units: {(#ContainerUnit.metadata.fqn): #ContainerUnit}
})

// From traits/workload/replicas.cue
#Replicas: close(core.#ComponentDefinition & {
    #traits: {(#ReplicasTrait.metadata.fqn): #ReplicasTrait}
})
```

### Migration Paths

**Simple → Standard:**

1. Create `values.cue` file
2. Move `#values` block from `module_definition.cue` to `values.cue`
3. Keep same package name
4. CUE automatically unifies

**Standard → Advanced:**

1. Create `components.cue` file
2. Move `#components` block from `module_definition.cue` to `components.cue`
3. Create additional files as needed
4. Keep same package name

**No rebuild needed** - CLI automatically detects all files.

### Template Customization

**After initialization, templates are fully customizable:**

```bash
# Initialize with template
opm mod init my-app --template standard

# Edit generated files
vim module_definition.cue
vim values.cue

# Add additional files
vim scopes.cue
mkdir components && vim components/web.cue

# Build (CLI automatically discovers all files)
opm mod render . --output ./dist
```

**Templates are starting points, not constraints!**

---

## CLI Behavior Summary

### File Discovery:

```bash
# These all work:
opm mod render module_definition.cue           # Explicit file
opm mod render .                    # Auto-detect ./module_definition.cue
opm mod render ./my-app             # Auto-detect ./my-app/module_definition.cue
opm mod render ./my-app/module_definition.cue  # Explicit path
```

### Package Unification:

```bash
# CLI automatically unifies all .cue files in package
my-app/
├── module_definition.cue        # Package: myapp
├── values.cue        # Package: myapp  → Unified
├── components.cue    # Package: myapp  → Unified

# No imports needed between files in same package!
```

### Template Initialization:

```bash
# Official templates by short name (downloads from OCI, uses embedded fallback if offline)
opm mod init my-app --template simple
opm mod init my-app --template standard
opm mod init my-app --template advanced

# Official templates with specific version
opm mod init my-app --template opm.dev/templates/standard:v1.0.0-alpha.1

# Custom templates from OCI registry
opm mod init my-app --template oci://localhost:5000/custom-template:v2.0.0
opm mod init my-app --template oci://registry.io/myorg/webapp:v1.5.0
```

**Template Discovery Commands:**

```bash
# List available templates
opm mod template list

# Show template details
opm mod template show simple
opm mod template show opm.dev/templates/standard:v1.0.0-alpha.1
```

**Generated CUE Module Structure:**

`opm mod init` creates a proper CUE module with `cue.mod/module.cue`:

```cue
module: "example.com/my-app@v0"
language: {
    version: "v0.15.0"
}
source: {
    kind: "self"
}
```

**CUE Module Path Format:**
- Must use domain-like format: `example.com/<name>@v0`
- `@v0` indicates major version
- Invalid: `my-app` (no domain) or `my-app@v0` (no domain)

### Managing Dependencies:

After initializing a module, use `opm mod tidy` to manage dependencies:

```bash
# Initialize module
opm mod init my-app --template standard
cd my-app

# Edit cue.mod/module.cue to add dependencies
# deps: {
#     "github.com/open-platform-model/core@v0": {
#         v:       "v0.1.0"
#         default: true
#     }
# }

# Tidy dependencies (requires CUE v0.15.0+ in PATH)
opm mod tidy
```

**Requirements:**
- CUE v0.15.0 or higher must be installed and in PATH
- OPM automatically uses registry configuration from `~/.opm/config.cue`
- Sets `CUE_REGISTRY` environment variable when calling external CUE binary

**See:** [CLI Workflows - Managing Module Dependencies](CLI_WORKFLOWS.md#managing-module-dependencies) for complete workflow

### Build Output (Pure CUE Only):

```bash
# Authoring → Compiled (pure CUE)
opm mod render ./my-app --output ./dist/my-app.module_definition.cue

# Result: Single flattened Module file (pure CUE, no platform output)
```

### Rendering to Platform Resources:

```bash
# Option 1: Direct from ModuleDefinition
opm mod render ./my-app --platform kubernetes --output ./k8s

# Option 2: From pre-built Module (faster)
opm mod render ./dist/my-app.module_definition.cue --platform kubernetes --output ./k8s

# Result: Platform-specific resources (Kubernetes YAML, Docker Compose, etc.)
```

### Deployment:

```bash
# Compiled → Deployment
# Create ModuleRelease manually with concrete values
cat > ./releases/my-app-prod.release.cue << 'EOF'
package myapp

import core "opm.dev/core@v1"

core.#ModuleRelease & {
    metadata: {name: "my-app-prod", namespace: "production"}
    spec: {
        module: "./dist/my-app.module_definition.cue"
        values: {replicas: 5, image: "myapp:v1.2.3"}
    }
}
EOF

# Result: Single ModuleRelease file
```

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-03
