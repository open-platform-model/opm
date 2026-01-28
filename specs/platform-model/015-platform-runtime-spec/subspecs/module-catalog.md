# Module Catalog

**Parent Spec**: [015-platform-runtime-spec](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-28

## Overview

The `#ModuleCatalog` is the central registry of approved modules curated by Platform Operators. It serves as the authoritative source for which modules End Users can deploy, what versions are available, and what platform-specific customizations are applied.

## Design Principles

### 1. Registry-Centric Deployment

End Users can only deploy modules that exist in the catalog. This gives Platform Operators:
- Control over approved modules and versions
- Ability to apply platform-wide overlays
- Visibility into what's running in their environment

### 2. Multiple Module Sources

Catalogs support:
- **OCI references**: `oci://registry.example.com/modules/webapp@v1.0.0`
- **Local paths**: `file://./modules/webapp` (for development)
- **Git references**: (future) `git://github.com/example/module@v1.0.0`

### 3. Version Constraints

Platform Operators can pin exact versions or specify ranges:
- `1.0.0` - Exact version
- `^1.0.0` - Compatible versions (>=1.0.0, <2.0.0)
- `~1.0.0` - Patch versions (>=1.0.0, <1.1.0)
- `latest` - Most recent version

## Schema

### #ModuleCatalog

```cue
#ModuleCatalog: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "ModuleCatalog"
    
    metadata: {
        name!:        string  // Catalog name (e.g., "production", "staging")
        namespace?:   string  // Optional: restrict to namespace
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }
    
    // Registry of approved modules
    modules: [Name=string]: #CatalogModule & {
        metadata: name: string | *Name  // Module name defaults to map key
    }
})
```

### #CatalogModule

```cue
#CatalogModule: close({
    metadata: {
        name!:        string
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }
    
    // Module source location
    source!: #ModuleSource
    
    // Version constraint
    version!: string  // Semantic version or range
    
    // Platform overlays applied to this module
    // These merge with the module's values in order
    overlays?: [...#Overlay]
    
    // Namespace restrictions
    // Empty = module available in all namespaces
    // Non-empty = module only available in listed namespaces
    allowedNamespaces?: [...string]
    
    // Access control (future)
    // Which users/groups can deploy this module
    allowedUsers?: [...string]
    allowedGroups?: [...string]
})
```

### #ModuleSource

```cue
#ModuleSource: {
    // OCI registry reference
    oci?: string & =~"^oci://.+$"
    
    // Local filesystem path (for development)
    local?: string & =~"^file://.+$"
    
    // Git repository (future)
    git?: {
        url:    string
        ref?:   string  // branch, tag, or commit
        path?:  string  // subpath within repo
    }
} & (
    {oci!: string} |
    {local!: string} |
    {git!: _}
)
```

### #Overlay

```cue
#Overlay: {
    // Overlay name (for provenance tracking)
    name?: string
    
    // Values to merge (CUE, YAML, or JSON)
    // Inline values
    values?: _
    
    // Or reference to file
    valuesFile?: string
    
    // Components to add/override
    components?: [string]: #Component
    
    // Scopes to add/override
    scopes?: [string]: #Scope
} & (
    {values!: _} |
    {valuesFile!: string}
)
```

## Examples

### Example 1: Basic Catalog with OCI Modules

```cue
package main

import "opm.dev/core@v0"

catalog: core.#ModuleCatalog & {
    metadata: {
        name: "production"
        description: "Production-approved modules"
    }
    
    modules: {
        webapp: {
            source: oci: "oci://registry.example.com/modules/webapp"
            version: "1.0.0"
        }
        
        api: {
            source: oci: "oci://registry.example.com/modules/api"
            version: "^2.0.0"  // Allow 2.x.x versions
        }
    }
}
```

### Example 2: Catalog with Platform Overlays

```cue
catalog: core.#ModuleCatalog & {
    metadata: name: "production"
    
    modules: {
        webapp: {
            source: oci: "oci://registry.example.com/modules/webapp"
            version: "1.0.0"
            
            // Platform-enforced configuration
            overlays: [{
                name: "production-defaults"
                values: {
                    replicas: 3              // Locked (concrete)
                    image: *"nginx:latest" | _  // Default (can override)
                    resources: limits: {
                        cpu:    "2000m"
                        memory: "2Gi"
                    }
                }
            }]
        }
    }
}
```

### Example 3: Namespace-Restricted Module

```cue
catalog: core.#ModuleCatalog & {
    metadata: name: "production"
    
    modules: {
        // High-privilege module restricted to specific namespaces
        database: {
            source: oci: "oci://registry.example.com/modules/postgres"
            version: "15.0.0"
            
            // Only these namespaces can deploy this module
            allowedNamespaces: ["data-tier", "backend"]
        }
    }
}
```

### Example 4: Local Development Catalog

```cue
catalog: core.#ModuleCatalog & {
    metadata: name: "dev"
    
    modules: {
        webapp: {
            source: local: "file://./modules/webapp"
            version: "0.1.0-dev"
        }
    }
}
```

## Functional Requirements

- **FR-MC-001**: `#ModuleCatalog` MUST contain a `modules` map of approved modules
- **FR-MC-002**: Each module MUST have a `source` (OCI, local, or git)
- **FR-MC-003**: Each module MUST have a `version` constraint
- **FR-MC-004**: Modules MAY have `overlays` that merge with module values
- **FR-MC-005**: Modules MAY restrict deployment to specific namespaces via `allowedNamespaces`
- **FR-MC-006**: Overlays MUST merge in order (later overlays override earlier ones)
- **FR-MC-007**: Catalog MUST validate at creation time (all sources resolvable, overlays valid)
- **FR-MC-008**: End User attempting to deploy non-catalog module MUST receive clear error

## Validation Rules

| Rule | Validation |
|------|------------|
| **Unique module names** | No duplicate `modules` keys within catalog |
| **Valid sources** | Source URLs must be well-formed |
| **Valid versions** | Version constraints must be valid semver |
| **Overlay satisfaction** | Overlays must satisfy module's `config` schema |
| **Namespace validation** | `allowedNamespaces` must be valid namespace names |

## CLI Integration

### Commands

```bash
# Create catalog
opm catalog create production

# Add module to catalog
opm catalog add webapp \
  --source oci://registry.example.com/modules/webapp \
  --version 1.0.0

# Add module with overlay
opm catalog add webapp \
  --source oci://registry.example.com/modules/webapp \
  --version 1.0.0 \
  --overlay platform-values.cue

# List catalog modules
opm catalog list

# Show module details
opm catalog get webapp

# Validate catalog
opm catalog validate production.cue

# Remove module from catalog
opm catalog remove webapp
```

## Acceptance Criteria

1. **Given** a Platform Operator has OCI module references
2. **When** they create a `#ModuleCatalog` with those references
3. **Then** the catalog validates successfully

4. **Given** a catalog with module overlays
5. **When** an End User deploys the module
6. **Then** the overlays are applied to the module values

7. **Given** a module restricted to specific namespaces
8. **When** an End User attempts to deploy to a non-allowed namespace
9. **Then** the deployment is rejected with clear error

## Edge Cases

| Case | Behavior |
|------|----------|
| Module source unreachable | Catalog validation fails with clear error |
| Overlay doesn't satisfy config | Catalog validation fails |
| Version constraint invalid | Catalog validation fails |
| Conflicting overlays | Later overlay wins (deep merge) |
| Module not in catalog | Deployment blocked immediately |
| Namespace restriction violation | Deployment blocked with error |

## Success Criteria

- **SC-MC-001**: Platform Operator can create catalog and add module in under 2 minutes
- **SC-MC-002**: Catalog validation catches all configuration errors before deployment
- **SC-MC-003**: Error messages clearly indicate which module/overlay failed and why
