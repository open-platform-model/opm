# Bundle Definition Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-11-03

## Overview

Bundles are OPM's mechanism for **grouping and distributing multiple modules together** as a cohesive unit. While modules define individual applications or services, bundles enable platform teams to package related modules for easier distribution, versioning, and deployment management.

### Core Principles

- **Aggregation**: Bundles collect multiple modules into a single distributable unit
- **Three-Layer Architecture**: BundleDefinition → Bundle → BundleRelease
- **Value Hierarchies**: Bundle-level values propagate to contained modules
- **Parallel to Modules**: Bundles follow the same architectural patterns as modules
- **Distribution Focus**: Optimized for sharing complete application stacks

### What Bundles Represent

Bundles can package:

- **Full-stack applications**: Frontend + Backend + Database modules
- **Platform capabilities**: Observability + Security + Networking modules
- **Multi-tenant systems**: Tenant-specific module configurations
- **Microservice ecosystems**: Related service modules with dependencies
- **Environment sets**: Development + Staging + Production module variants

### Three-Layer Architecture

OPM uses a three-layer architecture for bundles, mirroring the module architecture:

| Layer | Type | Purpose | Created By | State |
|-------|------|---------|------------|-------|
| **Layer 1: Authoring** | `#BundleDefinition` | Developer-friendly authoring | Platform/DevOps teams | Flexible (incomplete values allowed) |
| **Layer 2: Compiled** | `#Bundle` | Optimized intermediate representation | CLI (`opm bundle build`) | Optimized (pure CUE, single file) |
| **Layer 3: Deployment** | `#BundleRelease` | Concrete deployment instance | Users/Automation | Concrete (all values closed) |

**Flow:**

```text
BundleDefinition (modules/#modulesDefinitions)
    ↓ opm bundle build
Bundle (flattened #modules)
    ↓ + concrete values
BundleRelease (deployed)
```

### Bundle vs Module

| Aspect | Bundle | Module |
|--------|--------|--------|
| **Purpose** | Groups multiple modules | Defines application/service |
| **Contains** | ModuleDefinitions (Layer 1) or Modules (Layer 2) | Components |
| **Field Name (Layer 1)** | `#modulesDefinitions` | `#components` |
| **Field Name (Layer 2)** | `#modules` | `#components` |
| **Value Schema** | Aggregates module values | Component-specific values |
| **Use Case** | Distribution, packaging | Application definition |

---

## Bundle Definition Types

OPM provides three bundle types, one for each architectural layer:

### #BundleDefinition (Layer 1: Authoring)

**Purpose:** Human-friendly authoring format for platform teams

**Contains:** ModuleDefinitions (not Modules)

**Characteristics:**

- Flexible structure allowing incomplete values
- Contains `#modulesDefinitions` map of ModuleDefinitions
- Value schema aggregates module value schemas
- Metadata includes `apiVersion`, `name`, and `fqn`

**Created by:** Platform teams, DevOps engineers

**File structure:**

```text
my-platform/
├── bundle.cue          # BundleDefinition + modulesDefinitions
├── values.cue          # Bundle-level value schema (optional)
└── cue.mod/
```

### #Bundle (Layer 2: Compiled)

**Purpose:** Optimized intermediate representation for performance

**Contains:** Flattened Modules (not ModuleDefinitions)

**Characteristics:**

- Single file, pure CUE output
- Contains `#modules` map of flattened Modules
- ModuleDefinitions compiled to Modules
- Blueprints expanded, optimizations applied
- Value schemas preserved from BundleDefinition

**Created by:** `opm bundle build` command

**Output:** Single `.bundle.cue` file

### #BundleRelease (Layer 3: Deployment)

**Purpose:** Concrete deployment instance targeting specific environment

**Contains:** Reference to Bundle + concrete values

**Characteristics:**

- All values are concrete (closed)
- References a Bundle (not BundleDefinition)
- Includes deployment metadata (labels, annotations)
- Has status tracking (phase, message)
- Metadata has NO `apiVersion` or `fqn` (instance type)

**Created by:** Users, deployment automation, GitOps systems

---

## Hybrid Structure

Bundles use OPM's two-level structure pattern:

**Root Level (Fixed):**

- `apiVersion: "opm.dev/v1/core"` - Fixed OPM core version
- `kind: "Bundle"` or `"BundleRelease"` - Identifies bundle type

**Metadata Level (Element-Specific):**

- `metadata.apiVersion` - Bundle-specific version (e.g., `"opm.dev/bundles/core@v1"`)
- `metadata.name` - Bundle name (e.g., `"FullStackApp"`)
- `metadata.fqn` - Computed as `"\(apiVersion)#\(name)"`

**Exception:** `#BundleRelease` is an instance type and has NO `metadata.apiVersion` or `metadata.fqn`.

This structure provides:

- **Kubernetes compatibility**: Root fields match K8s manifest structure
- **Independent versioning**: Bundles can version separately from OPM core
- **Clean exports**: Definitions export as standard K8s-like resources

See [Definition Structure](DEFINITION_STRUCTURE.md) for complete details.

---

## Field Reference

### #BundleDefinition Fields

#### apiVersion (Root Level)

**Type:** `string`
**Required:** Yes
**Fixed Value:** `"opm.dev/v1/core"`

Identifies this object as an OPM core v1 definition. This field is fixed for all v1 bundles and represents the OPM core schema version, not the bundle's own version.

```cue
apiVersion: "opm.dev/v1/core"  // Always this value for v1 bundles
```

#### kind (Root Level)

**Type:** `string`
**Required:** Yes
**Fixed Value:** `"Bundle"`

Identifies this object as a Bundle definition.

```cue
kind: "Bundle"  // Always this value for BundleDefinition and Bundle
```

#### metadata.apiVersion (Metadata Level)

**Type:** `#NameType`
**Required:** Yes (for BundleDefinition and Bundle)
**Pattern:** `<domain>/<category>/<subcategory>@v<major>`

The element-specific version path for this bundle. This allows the bundle to version independently from the OPM core schema.

**Examples:**

```cue
apiVersion: "opm.dev/bundles/core@v1"
apiVersion: "opm.dev/bundles/platform@v1"
apiVersion: "github.com/myorg/bundles/custom@v1"
```

**Best Practices:**

- Use semantic grouping: `domain/bundles/category@version`
- Official OPM bundles use `opm.dev/bundles/*`
- Third-party bundles use your domain or GitHub path
- Major version in @v format (e.g., `@v1`, `@v2`)

#### metadata.name (Metadata Level)

**Type:** `#NameType`
**Required:** Yes
**Pattern:** PascalCase, starts with uppercase letter

The bundle's name, which must be unique within the `metadata.apiVersion` namespace.

**Examples:**

```cue
name: "FullStackApp"
name: "ObservabilityPlatform"
name: "CoreInfrastructure"
```

**Naming Rules:**

- Must start with uppercase letter
- Use PascalCase (e.g., `FullStackApp`, not `full_stack_app`)
- Be descriptive, not abbreviated (e.g., `ObservabilityPlatform`, not `ObsPlatform`)
- Describe the bundle's purpose, not the implementation

#### metadata.fqn (Metadata Level)

**Type:** `#FQNType`
**Required:** Computed (not manually set)
**Pattern:** `<repo-path>@v<major>#<Name>`

The Fully Qualified Name, automatically computed from `metadata.apiVersion` and `metadata.name`.

```cue
metadata: {
    apiVersion: "opm.dev/bundles/core@v1"
    name:       "FullStackApp"
    fqn:        "\(apiVersion)#\(name)"  // Result: "opm.dev/bundles/core@v1#FullStackApp"
}
```

**Key Points:**

- **Never manually set** - always use the interpolation pattern
- **Globally unique** - serves as the bundle's identifier throughout OPM
- **Used for indexing** - registries use FQN as bundle keys
- **Matches regex**: `^([a-z0-9.-]+(?:/[a-z0-9.-]+)+)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$`

#### metadata.description (Metadata Level)

**Type:** `string`
**Required:** No
**Purpose:** Human-readable explanation of the bundle's purpose

```cue
description: "Full-stack web application with frontend, backend, and database"
description: "Complete observability platform with monitoring, logging, and tracing"
description: "Core infrastructure modules for multi-tenant Kubernetes platform"
```

**Best Practices:**

- Keep concise (1-2 sentences)
- Explain what's included in the bundle
- Mention key capabilities or use cases
- Use sentence case with period

#### metadata.labels (Metadata Level)

**Type:** `#LabelsAnnotationsType` (`[string]: string | int | bool | array`)
**Required:** No
**Purpose:** Categorization and filtering for OPM tooling

Labels are used by the OPM system for:

- **Categorization**: Grouping bundles by type or purpose
- **Registry filtering**: Finding bundles in catalogs
- **Validation**: Enforcing organizational policies
- **Selection**: Choosing bundles based on criteria

**Examples:**

```cue
labels: {
    "core.opm.dev/category": "application"
    "core.opm.dev/tier":     "full-stack"
}

labels: {
    "core.opm.dev/category": "platform"
    "core.opm.dev/type":     "observability"
}

labels: {
    "myorg.com/team":        "platform"
    "myorg.com/criticality": "high"
}
```

#### metadata.annotations (Metadata Level)

**Type:** `#LabelsAnnotationsType`
**Required:** No
**Purpose:** Additional metadata NOT used for selection/matching

Annotations provide hints but are not used for matching logic.

**Examples:**

```cue
annotations: {
    "opm.dev/documentation": "https://opm.dev/docs/bundles/fullstack"
    "opm.dev/source":        "official"
}

annotations: {
    "myorg.com/owner":       "platform-team"
    "myorg.com/review-date": "2025-12-31"
}
```

#### #modulesDefinitions (BundleDefinition-Specific)

**Type:** `#ModuleDefinitionMap` (`[string]: #ModuleDefinition`)
**Required:** Yes (for BundleDefinition)
**Purpose:** Contains ModuleDefinitions to be bundled together

This is the **defining field of BundleDefinition** - it contains the collection of ModuleDefinitions that make up this bundle.

**Key Characteristics:**

- Map structure: `[moduleName=string]: #ModuleDefinition`
- Contains ModuleDefinitions (NOT Modules)
- Each module is a complete ModuleDefinition with components and value schema
- Module names become keys in the bundle's value schema

**Example:**

```cue
#modulesDefinitions: {
    frontend: #ModuleDefinition & {
        metadata: {
            apiVersion: "opm.dev/modules/core@v1"
            name:       "Frontend"
            version:    "1.0.0"
        }
        #components: {
            web: {...}
        }
        #values: {
            web: {...}
        }
    }

    backend: #ModuleDefinition & {
        metadata: {
            apiVersion: "opm.dev/modules/core@v1"
            name:       "Backend"
            version:    "1.0.0"
        }
        #components: {
            api: {...}
            db:  {...}
        }
        #values: {
            api: {...}
            db:  {...}
        }
    }
}
```

#### #modules (Bundle-Specific)

**Type:** `#ModuleMap` (`[string]: #Module`)
**Required:** Yes (for Bundle)
**Purpose:** Contains flattened Modules (compiled from ModuleDefinitions)

This field appears in Layer 2 (Bundle) after `opm bundle build` compiles the BundleDefinition.

**Key Characteristics:**

- Map structure: `[moduleName=string]: #Module`
- Contains flattened Modules (NOT ModuleDefinitions)
- Blueprints expanded to Units + Traits
- Optimizations applied
- Value schemas preserved

**Example:**

```cue
#modules: {
    frontend: #Module & {
        metadata: {...}
        #components: {
            // Flattened components
        }
        #values: {
            // Preserved value schema
        }
    }

    backend: #Module & {
        metadata: {...}
        #components: {
            // Flattened components
        }
        #values: {
            // Preserved value schema
        }
    }
}
```

#### #values (Value Schema)

**Type:** CUE schema
**Required:** Yes
**Purpose:** OpenAPIv3-compatible schema defining the bundle's configuration structure

The `#values` field aggregates value schemas from all contained modules.

**Key Characteristics:**

- Hierarchical structure: `{moduleName: {moduleValueSchema}}`
- Each module's value schema is nested under its name
- Preserves all constraints from module value schemas
- Uses # prefix: Allows incomplete/template values
- OpenAPIv3-compatible: Can be converted to OpenAPI schemas

**Example:**

```cue
#values: {
    frontend: {
        web: {
            image!:    string
            replicas?: int & >=1 & <=10 | *3
        }
    }
    backend: {
        api: {
            image!:    string
            replicas?: int & >=1 & <=5 | *2
        }
        db: {
            image!:      string
            volumeSize!: string
        }
    }
}
```

### #BundleRelease Fields

#### apiVersion (Root Level)

**Type:** `string`
**Required:** Yes
**Fixed Value:** `"opm.dev/v1/core"`

Same as BundleDefinition.

```cue
apiVersion: "opm.dev/v1/core"
```

#### kind (Root Level)

**Type:** `string`
**Required:** Yes
**Fixed Value:** `"BundleRelease"`

Identifies this object as a BundleRelease (deployment instance).

```cue
kind: "BundleRelease"
```

#### metadata.name (Metadata Level)

**Type:** `string`
**Required:** Yes
**Pattern:** Lowercase with hyphens (Kubernetes-style)

The deployment instance name. Unlike BundleDefinition, this uses lowercase Kubernetes-style naming.

**Note:** BundleRelease metadata does NOT have `apiVersion` or `fqn` fields - it's an instance type, not a definition type.

**Examples:**

```cue
name: "fullstack-production"
name: "observability-staging"
name: "tenant-acme-prod"
```

#### metadata.labels (Metadata Level)

**Type:** `#LabelsAnnotationsType`
**Required:** No
**Purpose:** Deployment-specific labels for filtering and organization

**Examples:**

```cue
labels: {
    "environment": "production"
    "team":        "platform"
    "project":     "fullstack-app"
}
```

#### metadata.annotations (Metadata Level)

**Type:** `#LabelsAnnotationsType`
**Required:** No
**Purpose:** Deployment-specific metadata

**Examples:**

```cue
annotations: {
    "deployed-by":    "argocd"
    "deployed-at":    "2025-11-03T10:30:00Z"
    "git-commit":     "abc123def"
    "ticket":         "PLAT-1234"
}
```

#### bundle (BundleRelease-Specific)

**Type:** `#Bundle`
**Required:** Yes
**Purpose:** Reference to the Bundle to deploy

This field contains a complete Bundle (Layer 2), not a BundleDefinition.

**Key Points:**

- Must reference a `#Bundle` (flattened), not a `#BundleDefinition`
- Typically a reference to a pre-built bundle file
- Can be inline or external reference

**Example:**

```cue
// Reference to external bundle
bundle: myBundle

// Or inline
bundle: #Bundle & {
    metadata: {...}
    #modules: {...}
    #values:  {...}
}
```

#### values (BundleRelease-Specific)

**Type:** Closed schema matching `bundle.#values`
**Required:** Yes
**Purpose:** Concrete values for deployment

All values must be concrete (no incomplete fields) and must conform to the bundle's value schema.

**Key Characteristics:**

- Closed: `close(bundle.#values)`
- All required fields must be provided
- All values must be concrete (no templates)
- Structure matches bundle's value hierarchy

**Example:**

```cue
values: {
    frontend: {
        web: {
            image:    "myregistry.io/frontend:v2.1.0"
            replicas: 5
        }
    }
    backend: {
        api: {
            image:    "myregistry.io/backend:v2.1.0"
            replicas: 3
        }
        db: {
            image:      "postgres:14"
            volumeSize: "200Gi"
        }
    }
}
```

#### status (BundleRelease-Specific)

**Type:** Object with `phase` and optional `message`
**Required:** No (populated by deployment system)
**Purpose:** Tracks deployment status

**Fields:**

- `phase`: `"pending"` | `"deployed"` | `"failed"` | `"unknown"` (default: `"pending"`)
- `message`: Optional human-readable status message

**Example:**

```cue
status: {
    phase:   "deployed"
    message: "Successfully deployed full-stack application"
}

status: {
    phase:   "failed"
    message: "Backend module failed health checks"
}
```

---

## Complete Examples

### Example 1: Simple Full-Stack Bundle

**BundleDefinition (Layer 1):**

```cue
package myapp

import (
    core "opm.dev/core@v1"
)

// BundleDefinition: Authored by platform team
myFullStackBundle: core.#BundleDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Bundle"

    metadata: {
        apiVersion:  "opm.dev/bundles/core@v1"
        name:        "FullStackApp"
        description: "Full-stack web application with frontend and backend"
        labels: {
            "core.opm.dev/category": "application"
            "core.opm.dev/tier":     "full-stack"
        }
    }

    #modulesDefinitions: {
        frontend: core.#ModuleDefinition & {
            metadata: {
                apiVersion:  "opm.dev/modules/core@v1"
                name:        "Frontend"
                version:     "1.0.0"
                description: "Frontend web application"
            }

            #components: {
                web: core.#ComponentDefinition & {
                    metadata: name: "web-server"

                    #Container
                    #Replicas
                }
            }

            #values: {
                web: {
                    image!:    string
                    replicas?: int & >=1 & <=10 | *3
                }
            }
        }

        backend: core.#ModuleDefinition & {
            metadata: {
                apiVersion:  "opm.dev/modules/core@v1"
                name:        "Backend"
                version:     "1.0.0"
                description: "Backend API service"
            }

            #components: {
                api: core.#ComponentDefinition & {
                    metadata: name: "api-server"

                    #Container
                    #Replicas
                }
            }

            #values: {
                api: {
                    image!:    string
                    replicas?: int & >=1 & <=5 | *2
                }
            }
        }
    }

    #values: {
        frontend: {
            web: {
                image!:    string
                replicas?: int & >=1 & <=10 | *3
            }
        }
        backend: {
            api: {
                image!:    string
                replicas?: int & >=1 & <=5 | *2
            }
        }
    }
}
```

**Bundle (Layer 2) - Generated by `opm bundle build`:**

```cue
package myapp

// Bundle: Compiled/flattened from BundleDefinition
// Generated by: opm bundle build ./bundle.cue --output ./dist/fullstack.bundle.cue

#Bundle & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Bundle"

    metadata: {
        apiVersion:  "opm.dev/bundles/core@v1"
        name:        "FullStackApp"
        description: "Full-stack web application (compiled)"
    }

    #modules: {
        frontend: #Module & {
            metadata: {
                apiVersion: "opm.dev/modules/core@v1"
                name:       "Frontend"
                version:    "1.0.0"
            }

            #components: {
                // Flattened components with expanded blueprints
                web: {
                    metadata: name: "web-server"
                    // Units and traits expanded
                    #units: {...}
                    #traits: {...}
                    spec: {
                        // Merged spec fields
                    }
                }
            }

            #values: {
                web: {
                    image!:    string
                    replicas?: int & >=1 & <=10 | *3
                }
            }
        }

        backend: #Module & {
            metadata: {
                apiVersion: "opm.dev/modules/core@v1"
                name:       "Backend"
                version:    "1.0.0"
            }

            #components: {
                api: {
                    metadata: name: "api-server"
                    #units: {...}
                    #traits: {...}
                    spec: {...}
                }
            }

            #values: {
                api: {
                    image!:    string
                    replicas?: int & >=1 & <=5 | *2
                }
            }
        }
    }

    #values: {
        frontend: {
            web: {
                image!:    string
                replicas?: int & >=1 & <=10 | *3
            }
        }
        backend: {
            api: {
                image!:    string
                replicas?: int & >=1 & <=5 | *2
            }
        }
    }
}
```

**BundleRelease (Layer 3):**

```cue
package myapp

import "path/to/dist/fullstack.bundle.cue"

// BundleRelease: Concrete deployment instance
fullstackProduction: #BundleRelease & {
    apiVersion: "opm.dev/v1/core"
    kind:       "BundleRelease"

    metadata: {
        name: "fullstack-production"
        labels: {
            "environment": "production"
            "team":        "platform"
        }
        annotations: {
            "deployed-by": "argocd"
            "git-commit":  "abc123def"
        }
    }

    // Reference the compiled Bundle
    bundle: fullstack.bundle.cue.myFullStackBundle

    // Concrete values for production
    values: {
        frontend: {
            web: {
                image:    "myregistry.io/frontend:v2.1.0"
                replicas: 5
            }
        }
        backend: {
            api: {
                image:    "myregistry.io/backend:v2.1.0"
                replicas: 3
            }
        }
    }

    status: {
        phase:   "deployed"
        message: "Successfully deployed to production"
    }
}
```

### Example 2: Observability Platform Bundle

**BundleDefinition:**

```cue
observabilityBundle: #BundleDefinition & {
    metadata: {
        apiVersion:  "opm.dev/bundles/platform@v1"
        name:        "ObservabilityPlatform"
        description: "Complete observability platform with monitoring, logging, and tracing"
        labels: {
            "core.opm.dev/category": "platform"
            "core.opm.dev/type":     "observability"
        }
    }

    #modulesDefinitions: {
        monitoring: #ModuleDefinition & {
            metadata: {
                apiVersion: "opm.dev/modules/observability@v1"
                name:       "Monitoring"
                version:    "1.0.0"
            }

            #components: {
                prometheus: {...}
                grafana:    {...}
            }

            #values: {
                prometheus: {
                    retention!:    string
                    storageSize!:  string
                }
                grafana: {
                    adminPassword!: string
                }
            }
        }

        logging: #ModuleDefinition & {
            metadata: {
                apiVersion: "opm.dev/modules/observability@v1"
                name:       "Logging"
                version:    "1.0.0"
            }

            #components: {
                loki:       {...}
                promtail:   {...}
            }

            #values: {
                loki: {
                    storageSize!: string
                }
            }
        }

        tracing: #ModuleDefinition & {
            metadata: {
                apiVersion: "opm.dev/modules/observability@v1"
                name:       "Tracing"
                version:    "1.0.0"
            }

            #components: {
                tempo: {...}
            }

            #values: {
                tempo: {
                    storageSize!: string
                }
            }
        }
    }

    #values: {
        monitoring: {
            prometheus: {
                retention!:    string
                storageSize!:  string
            }
            grafana: {
                adminPassword!: string
            }
        }
        logging: {
            loki: {
                storageSize!: string
            }
        }
        tracing: {
            tempo: {
                storageSize!: string
            }
        }
    }
}
```

**BundleRelease:**

```cue
observabilityStaging: #BundleRelease & {
    metadata: {
        name: "observability-staging"
        labels: {
            "environment": "staging"
            "team":        "sre"
        }
    }

    bundle: observabilityBundle  // Reference to compiled Bundle

    values: {
        monitoring: {
            prometheus: {
                retention:    "30d"
                storageSize:  "100Gi"
            }
            grafana: {
                adminPassword: "changeme123"  // From secret in production
            }
        }
        logging: {
            loki: {
                storageSize: "50Gi"
            }
        }
        tracing: {
            tempo: {
                storageSize: "50Gi"
            }
        }
    }

    status: {
        phase:   "deployed"
        message: "Observability platform running in staging"
    }
}
```

### Example 3: Multi-Tenant SaaS Bundle

**BundleDefinition:**

```cue
saasBundle: #BundleDefinition & {
    metadata: {
        apiVersion:  "opm.dev/bundles/saas@v1"
        name:        "MultiTenantSaaS"
        description: "Complete SaaS platform for multi-tenant deployments"
    }

    #modulesDefinitions: {
        frontend: #ModuleDefinition & {...}
        backend:  #ModuleDefinition & {...}
        database: #ModuleDefinition & {...}
        cache:    #ModuleDefinition & {...}
        queue:    #ModuleDefinition & {...}
    }

    #values: {
        frontend: {...}
        backend:  {...}
        database: {
            instance!:     string
            storageSize!:  string
            backupEnabled: bool | *true
        }
        cache: {
            memorySize!: string
        }
        queue: {
            replicas!: int & >=1 & <=10
        }
    }
}
```

**BundleRelease (Tenant-Specific):**

```cue
tenantAcmeProduction: #BundleRelease & {
    metadata: {
        name: "tenant-acme-prod"
        labels: {
            "tenant":      "acme-corp"
            "environment": "production"
            "tier":        "premium"
        }
    }

    bundle: saasBundle

    values: {
        frontend: {
            image:    "myregistry.io/saas-frontend:v3.2.0"
            replicas: 10
            domain:   "acme.mysaas.com"
        }
        backend: {
            image:    "myregistry.io/saas-backend:v3.2.0"
            replicas: 15
        }
        database: {
            instance:       "db-m5-xlarge"
            storageSize:    "500Gi"
            backupEnabled:  true
        }
        cache: {
            memorySize: "64Gi"
        }
        queue: {
            replicas: 5
        }
    }

    status: {
        phase:   "deployed"
        message: "ACME Corp production tenant healthy"
    }
}
```

---

## Bundle Workflow

### Development Workflow

**1. Author BundleDefinition**

Platform team creates bundle with ModuleDefinitions:

```bash
# Directory structure
my-platform/
├── bundle.cue          # BundleDefinition
├── values.cue          # Value schema (optional)
├── modules/
│   ├── frontend.cue
│   ├── backend.cue
│   └── database.cue
└── cue.mod/
```

**2. Build Bundle**

Compile BundleDefinition to optimized Bundle:

```bash
# Build to single .bundle.cue file
opm bundle build ./bundle.cue --output ./dist/myapp.bundle.cue

# Output: Pure CUE, flattened, optimized
```

**3. Render for Platform**

Generate platform-specific resources (YAML/JSON):

```bash
# Option 1: Render from BundleDefinition
opm bundle render ./bundle.cue \
    --platform kubernetes \
    --output ./k8s \
    --values ./prod-values.cue

# Option 2: Render from compiled Bundle (faster)
opm bundle render ./dist/myapp.bundle.cue \
    --platform kubernetes \
    --output ./k8s \
    --values ./prod-values.cue
```

**4. Create BundleRelease**

Define deployment instance with concrete values:

```cue
// release-prod.cue
import "dist/myapp.bundle.cue"

prodRelease: #BundleRelease & {
    metadata: name: "myapp-production"
    bundle: myapp.bundle.cue.myBundle
    values: {
        // Concrete values for production
    }
}
```

**5. Apply Release**

Deploy to target platform:

```bash
opm bundle apply ./release-prod.cue \
    --platform kubernetes \
    --output ./deploy
```

### CI/CD Integration

**GitOps Example:**

```yaml
# .github/workflows/deploy.yml
name: Deploy Bundle

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install OPM CLI
        run: |
          curl -L https://github.com/opm/cli/releases/download/v1.0.0/opm-linux-amd64 -o opm
          chmod +x opm

      - name: Build Bundle
        run: ./opm bundle build ./bundle.cue --output ./dist/app.bundle.cue

      - name: Render for Kubernetes
        run: |
          ./opm bundle render ./dist/app.bundle.cue \
            --platform kubernetes \
            --values ./environments/${{ env.ENVIRONMENT }}/values.cue \
            --output ./deploy

      - name: Apply to Cluster
        run: kubectl apply -f ./deploy/
```

---

## CLI Integration

### opm bundle build

**Purpose:** Compile BundleDefinition to optimized Bundle (pure CUE)

**Syntax:**

```bash
opm bundle build <bundle-definition.cue> [flags]
```

**Flags:**

- `--output` - Output file path (default: stdout)
- `--verbose` - Enable verbose logging
- `--timings` - Show performance timing report

**Examples:**

```bash
# Build to file
opm bundle build ./bundle.cue --output ./dist/app.bundle.cue

# Build to stdout
opm bundle build ./bundle.cue

# With timing report
opm bundle build ./bundle.cue --output ./dist/app.bundle.cue --timings
```

**Output:** Single `.bundle.cue` file containing flattened `#Bundle`

### opm bundle render

**Purpose:** Generate platform-specific resources (YAML/JSON) from Bundle or BundleDefinition

**Syntax:**

```bash
opm bundle render <bundle.cue> --platform <platform> [flags]
```

**Flags:**

- `--platform` - Target platform (`kubernetes`, `docker-compose`, etc.)
- `--output` - Output directory (default: stdout)
- `--format` - Output format: `yaml` or `json` (default: `yaml`)
- `--values` - Additional values file(s)
- `--verbose` - Enable verbose logging

**Examples:**

```bash
# Render from BundleDefinition
opm bundle render ./bundle.cue --platform kubernetes --output ./k8s

# Render from compiled Bundle (faster)
opm bundle render ./dist/app.bundle.cue --platform kubernetes --output ./k8s

# With additional values
opm bundle render ./bundle.cue \
    --platform kubernetes \
    --values ./prod-values.cue \
    --output ./k8s

# Output as JSON
opm bundle render ./bundle.cue \
    --platform kubernetes \
    --format json \
    --output ./k8s
```

### opm bundle apply

**Purpose:** Build, render, and optionally apply BundleRelease to target platform

**Syntax:**

```bash
opm bundle apply <bundle-release.cue> --platform <platform> [flags]
```

**Flags:**

- `--platform` - Target platform
- `--output` - Output directory (if not applying directly)
- `--dry-run` - Generate resources without applying
- `--verbose` - Enable verbose logging

**Examples:**

```bash
# Apply BundleRelease to Kubernetes
opm bundle apply ./release-prod.cue --platform kubernetes

# Dry run (generate without applying)
opm bundle apply ./release-prod.cue --platform kubernetes --dry-run --output ./deploy

# Verbose output
opm bundle apply ./release-prod.cue --platform kubernetes --verbose
```

### opm bundle validate

**Purpose:** Validate BundleDefinition, Bundle, or BundleRelease

**Syntax:**

```bash
opm bundle validate <bundle.cue> [flags]
```

**Flags:**

- `--strict` - Enable strict validation
- `--verbose` - Show detailed validation output

**Examples:**

```bash
# Validate BundleDefinition
opm bundle validate ./bundle.cue

# Strict validation
opm bundle validate ./bundle.cue --strict

# Validate BundleRelease
opm bundle validate ./release-prod.cue
```

### Performance Benefits

Pre-building bundles provides significant performance improvements:

**Benchmarks:**

| Operation | BundleDefinition | Pre-Built Bundle | Improvement |
|-----------|------------------|------------------|-------------|
| Render time | 2.5s | 0.5s | **80% faster** |
| Memory usage | 150MB | 60MB | **60% reduction** |
| Cache efficiency | Low | High | N/A |

**Why Pre-Build?**

- **Faster CI/CD**: 50-80% faster rendering in pipelines
- **Lower Memory**: 40-60% memory reduction
- **Better Caching**: Pre-built bundles cache efficiently
- **Reproducibility**: Same compiled bundle across environments

---

## Use Cases

### 1. Full-Stack Application Distribution

**Scenario:** Platform team distributes complete application stack

```cue
fullStackBundle: #BundleDefinition & {
    #modulesDefinitions: {
        frontend:  #Frontend
        backend:   #Backend
        database:  #Database
        cache:     #Redis
    }
}
```

**Benefits:**

- Single artifact to version and distribute
- Consistent deployment across environments
- Simplified dependency management

### 2. Platform Capabilities

**Scenario:** SRE team packages observability, security, and networking

```cue
platformBundle: #BundleDefinition & {
    #modulesDefinitions: {
        monitoring:   #Prometheus + #Grafana
        logging:      #Loki + #Promtail
        tracing:      #Tempo
        security:     #Vault + #CertManager
        networking:   #Istio
    }
}
```

**Benefits:**

- Reusable platform capabilities
- Versioned together for compatibility
- Easy upgrades across clusters

### 3. Multi-Tenant SaaS

**Scenario:** SaaS provider deploys per-tenant instances

```cue
tenantBundle: #BundleDefinition & {
    #modulesDefinitions: {
        app:      #TenantApp
        database: #TenantDB
        cache:    #TenantCache
    }
}

// Deploy per tenant
tenantAcme: #BundleRelease & {
    bundle: tenantBundle
    values: {
        app:      {domain: "acme.saas.com", tier: "premium"}
        database: {instance: "db-large", storageSize: "500Gi"}
        cache:    {memorySize: "64Gi"}
    }
}
```

**Benefits:**

- Consistent tenant deployments
- Per-tenant value customization
- Simplified tenant lifecycle management

### 4. Environment Promotion

**Scenario:** Promote same bundle through dev → staging → production

```cue
myBundle: #BundleDefinition & {...}

// Dev
devRelease: #BundleRelease & {
    bundle: myBundle
    values: devValues
}

// Staging
stagingRelease: #BundleRelease & {
    bundle: myBundle
    values: stagingValues
}

// Production
prodRelease: #BundleRelease & {
    bundle: myBundle
    values: prodValues
}
```

**Benefits:**

- Same bundle artifact across environments
- Only values change between environments
- Confidence in production deployment

### 5. Marketplace/Registry Distribution

**Scenario:** Third-party bundles distributed via OCI registry

```bash
# Publish bundle to registry
opm bundle build ./bundle.cue --output ./dist/app.bundle.cue
opm bundle publish ./dist/app.bundle.cue \
    --registry oci://registry.opm.dev/bundles/myapp:v1.0.0

# Consumers pull and deploy
opm bundle pull oci://registry.opm.dev/bundles/myapp:v1.0.0
opm bundle apply ./myapp.bundle.cue --platform kubernetes
```

**Benefits:**

- Shareable, discoverable bundles
- Versioned distribution
- Standardized packaging

---

## Best Practices

### 1. Bundle Granularity

**DO:** Create bundles for cohesive, related modules

```cue
// ✅ Good: Related modules for complete application
fullStackBundle: #BundleDefinition & {
    #modulesDefinitions: {
        frontend: #Frontend
        backend:  #Backend
        database: #Database
    }
}
```

**DON'T:** Create overly broad or unrelated bundles

```cue
// ❌ Bad: Unrelated modules bundled together
everythingBundle: #BundleDefinition & {
    #modulesDefinitions: {
        app1Frontend:   #App1Frontend
        app1Backend:    #App1Backend
        app2Frontend:   #App2Frontend  // Different app!
        monitoring:     #Monitoring    // Platform concern!
    }
}
```

### 2. Value Schema Hierarchy

**DO:** Maintain clear value hierarchies

```cue
// ✅ Good: Clear module → component hierarchy
#values: {
    frontend: {
        web: {
            image!:    string
            replicas?: int
        }
    }
    backend: {
        api: {
            image!:    string
            replicas?: int
        }
    }
}
```

**DON'T:** Flatten or mix module values

```cue
// ❌ Bad: Flat structure loses module context
#values: {
    frontendImage!:    string
    frontendReplicas?: int
    backendImage!:     string
    backendReplicas?:  int
}
```

### 3. Module Independence

**DO:** Design modules to be independently deployable

```cue
// ✅ Good: Each module is self-contained
#modulesDefinitions: {
    frontend: #ModuleDefinition & {
        #components: {
            web: {...}  // Complete, deployable
        }
    }
    backend: #ModuleDefinition & {
        #components: {
            api: {...}  // Complete, deployable
        }
    }
}
```

**DON'T:** Create tight coupling between modules

```cue
// ❌ Bad: Frontend depends on backend internals
frontend: #ModuleDefinition & {
    #components: {
        web: {
            spec: {
                container: {
                    env: {
                        BACKEND_HOST: backend.#components.api.spec.hostname  // Coupling!
                    }
                }
            }
        }
    }
}
```

### 4. Version Management

**DO:** Version bundles independently from modules

```cue
bundle: #BundleDefinition & {
    metadata: {
        apiVersion: "opm.dev/bundles/core@v1"  // Bundle version
        name:       "FullStackApp"
    }

    #modulesDefinitions: {
        frontend: #ModuleDefinition & {
            metadata: {
                apiVersion: "opm.dev/modules/core@v1"  // Module version
                version:    "2.1.0"                     // Module release version
            }
        }
    }
}
```

### 5. Pre-Build for Production

**DO:** Build bundles before deployment

```bash
# Build once
opm bundle build ./bundle.cue --output ./dist/app.bundle.cue

# Deploy many times (faster)
opm bundle render ./dist/app.bundle.cue --platform kubernetes --output ./k8s
```

**Benefits:**

- 50-80% faster rendering
- Consistent artifacts across environments
- Better caching

### 6. Provide Sensible Defaults

**DO:** Include defaults in value schemas

```cue
#values: {
    frontend: {
        web: {
            image!:    string
            replicas?: int & >=1 & <=10 | *3  // Default: 3
        }
    }
}
```

**DON'T:** Require all values without defaults

```cue
// ❌ Bad: No defaults means verbose releases
#values: {
    frontend: {
        web: {
            image!:               string
            replicas!:            int
            cpu!:                 string
            memory!:              string
            storageSize!:         string
            logLevel!:            string
            timeout!:             int
            maxConnections!:      int
            // ... 20 more required fields
        }
    }
}
```

### 7. Document Bundle Purpose

**DO:** Provide clear descriptions

```cue
metadata: {
    description: "Full-stack web application with React frontend, Node.js backend, and PostgreSQL database. Includes monitoring and logging."
    labels: {
        "core.opm.dev/category": "application"
        "core.opm.dev/tier":     "full-stack"
    }
}
```

### 8. Use Labels for Organization

**DO:** Apply consistent labels

```cue
metadata: {
    labels: {
        "core.opm.dev/category": "platform"
        "core.opm.dev/type":     "observability"
        "myorg.com/team":        "sre"
        "myorg.com/criticality": "high"
    }
}
```

---

## Common Pitfalls

### 1. Confusing ModuleDefinitions vs Modules

**Wrong:**

```cue
// ❌ BundleDefinition should contain ModuleDefinitions
myBundle: #BundleDefinition & {
    #modules: {...}  // Wrong field name!
}
```

**Correct:**

```cue
// ✅ BundleDefinition contains ModuleDefinitions
myBundle: #BundleDefinition & {
    #modulesDefinitions: {...}  // Correct!
}

// ✅ Bundle contains Modules
myCompiledBundle: #Bundle & {
    #modules: {...}  // Correct for compiled bundle
}
```

### 2. Referencing BundleDefinition in BundleRelease

**Wrong:**

```cue
// ❌ BundleRelease must reference Bundle, not BundleDefinition
release: #BundleRelease & {
    bundle: myBundleDefinition  // Wrong!
}
```

**Correct:**

```cue
// ✅ BundleRelease references compiled Bundle
release: #BundleRelease & {
    bundle: myCompiledBundle  // Correct!
}
```

### 3. Including apiVersion in BundleRelease metadata

**Wrong:**

```cue
// ❌ BundleRelease metadata has NO apiVersion or fqn
release: #BundleRelease & {
    metadata: {
        apiVersion: "opm.dev/bundles/core@v1"  // Wrong!
        name:       "my-release"
        fqn:        "opm.dev/bundles/core@v1#MyRelease"  // Wrong!
    }
}
```

**Correct:**

```cue
// ✅ BundleRelease metadata is simple (instance type)
release: #BundleRelease & {
    metadata: {
        name: "my-release"  // Only name, labels, annotations
        labels: {
            "environment": "production"
        }
    }
}
```

### 4. Incomplete Values in BundleRelease

**Wrong:**

```cue
// ❌ BundleRelease values must be complete (closed)
release: #BundleRelease & {
    bundle: myBundle
    values: {
        frontend: {
            web: {
                image: string  // Wrong! Must be concrete
            }
        }
    }
}
```

**Correct:**

```cue
// ✅ All values must be concrete
release: #BundleRelease & {
    bundle: myBundle
    values: {
        frontend: {
            web: {
                image: "myregistry.io/frontend:v2.1.0"  // Concrete!
            }
        }
    }
}
```

### 5. Tight Module Coupling

**Wrong:**

```cue
// ❌ Modules should not directly reference each other
#modulesDefinitions: {
    frontend: #ModuleDefinition & {
        #components: {
            web: {
                spec: {
                    container: {
                        env: {
                            API_URL: backend.#components.api.spec.url  // Tight coupling!
                        }
                    }
                }
            }
        }
    }
}
```

**Correct:**

```cue
// ✅ Use values for cross-module references
#modulesDefinitions: {
    frontend: #ModuleDefinition & {
        #values: {
            web: {
                apiUrl!: string  // Externalize dependency
            }
        }
    }
}

// In BundleRelease
values: {
    frontend: {
        web: {
            apiUrl: "http://api-service:8080"  // Configure at deployment
        }
    }
}
```

---

## Rationale

### Why Three Layers?

**Layer 1 (BundleDefinition):** Human-friendly authoring

- **Flexibility**: Incomplete values, templates, inheritance
- **Maintainability**: Clear structure, modular organization
- **Developer Experience**: Easy to author and understand

**Layer 2 (Bundle):** Optimized intermediate representation

- **Performance**: 50-80% faster rendering
- **Caching**: Single file, efficient caching
- **Reproducibility**: Same artifact across environments

**Layer 3 (BundleRelease):** Concrete deployment

- **Immutability**: All values closed, no ambiguity
- **Traceability**: Clear what's deployed where
- **Status Tracking**: Deployment lifecycle management

### Why modulesDefinitions vs modules?

The field name difference (`#modulesDefinitions` vs `#modules`) is intentional:

- **#modulesDefinitions**: Contains ModuleDefinitions (flexible, authoring layer)
- **#modules**: Contains Modules (flattened, compiled layer)

This naming prevents confusion and makes the layer distinction explicit.

### Why Bundles Instead of Just Modules?

**Without Bundles:**

- Must manage multiple module files separately
- Inconsistent versioning across related modules
- Complex dependency management
- Harder to distribute complete applications

**With Bundles:**

- Single artifact for related modules
- Consistent versioning
- Simplified distribution
- Clear module relationships

### Why BundleRelease Doesn't Have apiVersion/fqn?

BundleRelease is an **instance type**, not a **definition type**:

- **Definitions** (BundleDefinition, Bundle): Reusable, versioned, globally unique (need apiVersion/fqn)
- **Instances** (BundleRelease): Concrete deployments, environment-specific (no versioning needed)

This follows the same pattern as ModuleRelease.

---

## See Also

- [Definition Structure](DEFINITION_STRUCTURE.md) - Two-level structure pattern
- [Definition Types](DEFINITION_TYPES.md) - All OPM definition types
- [Module Definition](MODULE_DEFINITION.md) - Module specification (bundles contain modules)
- [CLI Specification](CLI_SPEC.md) - Complete CLI documentation
- [Quick Reference](QUICK_REFERENCE.md) - One-page cheat sheet
- [FQN Specification](FQN_SPEC.md) - FQN format details

---

**Document Version:** 1.0.0-draft
**Date:** 2025-11-03
