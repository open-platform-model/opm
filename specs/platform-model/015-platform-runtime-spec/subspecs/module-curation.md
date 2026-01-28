# Module Curation

**Parent Spec**: [015-platform-runtime-spec](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-28

## Overview

Module curation is the process by which Platform Operators customize upstream modules for their platform. OPM supports two primary curation patterns: **Extend** and **Fork**.

## Design Principles

### 1. Composition Over Mutation

Prefer extending modules via CUE unification rather than forking and modifying source code.

### 2. Maintainability First

Choose the pattern that minimizes maintenance burden while meeting customization needs.

### 3. Explicit Customization

All platform customizations should be visible and documented in overlay files or platform module definitions.

## Curation Patterns

### Pattern A: Extend (Import + Unify)

Import an upstream module and apply customizations via CUE unification and overlay files.

**Use When:**
- Adding values, components, or scopes
- Overriding configuration values
- Applying platform-wide policies
- Maintaining upstream compatibility

**Benefits:**
- Automatic upstream updates (reimport)
- Clear separation of upstream vs platform concerns
- Minimal maintenance burden
- Preserves attribution to original module

**Limitations:**
- Cannot change existing component structure
- Cannot remove upstream components
- Limited to additive changes

---

### Pattern B: Fork (Git Fork)

Fork the upstream module git repository and make direct modifications.

**Use When:**
- Structural changes required (component architecture)
- Removing upstream components
- Extensive customization beyond unification
- Upstream module is not maintained

**Benefits:**
- Full control over module structure
- Can make any changes needed
- No import dependencies

**Limitations:**
- Manual upstream merge required
- Higher maintenance burden
- Loses clear upstream attribution
- May diverge significantly over time

## Extend Pattern Details

### Directory Structure

```
platform-repo/
├── catalog/
│   └── production.cue        # #ModuleCatalog definition
├── modules/
│   └── webapp/
│       ├── module.cue        # Import + extend upstream
│       └── overlays/
│           ├── platform.cue  # Platform values overlay
│           └── security.cue  # Security policy overlay
└── cue.mod/
    └── module.cue
```

### Example: Extend Upstream Module

**Upstream module** (`example.com/modules/webapp@v1`):

```cue
package webapp

#WebApp: #Module & {
    metadata: {
        apiVersion: "example.com/modules@v1"
        name:       "WebApp"
        version:    "1.0.0"
    }
    
    #components: {
        frontend: {
            #resources: container: #Container & {
                #spec: {
                    image!: string
                    port!:  int
                }
            }
        }
    }
    
    config: {
        image:    string
        port:     int & >0
        replicas: int & >=1
    }
    
    values: {
        port:     8080
        replicas: 1
    }
}
```

**Platform extension** (`platform-repo/modules/webapp/module.cue`):

```cue
package webapp

import upstream "example.com/modules/webapp@v1"

// Extend upstream module with platform customizations
#PlatformWebApp: upstream.#WebApp & {
    // Add platform-specific component
    #components: {
        monitoring: {
            #resources: sidecar: #Container & {
                #spec: image: "monitoring-agent:latest"
            }
        }
    }
    
    // Extend config schema with platform fields
    config: {
        environment: string & =~"^(dev|staging|prod)$"
        team:        string
    }
    
    // Add platform values
    values: {
        environment: "prod"
        team:        "platform"
    }
}
```

**Platform overlay** (`platform-repo/modules/webapp/overlays/platform.cue`):

```cue
package webapp

// Platform-enforced values
values: {
    replicas: 3              // Locked: concrete value
    image: *"nginx:1.25" | _  // Default: can override
    
    resources: {
        limits: {
            cpu:    "2000m"
            memory: "2Gi"
        }
    }
}
```

**Catalog entry** (`platform-repo/catalog/production.cue`):

```cue
package catalog

import "platform-repo/modules/webapp"

catalog: #ModuleCatalog & {
    metadata: name: "production"
    
    modules: {
        webapp: {
            // Reference the extended module
            source: local: "file://../modules/webapp"
            version: "1.0.0"
            
            // Apply platform overlays
            overlays: [
                {valuesFile: "../modules/webapp/overlays/platform.cue"},
                {valuesFile: "../modules/webapp/overlays/security.cue"},
            ]
        }
    }
}
```

## Fork Pattern Details

### Workflow

```
1. Fork upstream repository
   git clone https://github.com/upstream/webapp.git platform-webapp
   cd platform-webapp
   
2. Add upstream remote
   git remote add upstream https://github.com/upstream/webapp.git
   
3. Make modifications
   edit module.cue, values.cue, components...
   git commit -m "Platform customizations"
   
4. Periodically sync upstream
   git fetch upstream
   git merge upstream/main  # May have conflicts
   
5. Publish to catalog
   Add to catalog with git or local source
```

### Example: Fork with Structural Changes

**Forked module** (modified from upstream):

```cue
package webapp

#WebApp: #Module & {
    metadata: {
        apiVersion: "platform.example.com/modules@v1"
        name:       "PlatformWebApp"
        version:    "1.0.0-platform"
    }
    
    #components: {
        // REMOVED: frontend component (structural change)
        
        // ADDED: Combined app component
        app: {
            #resources: {
                container: #Container & {
                    #spec: {
                        image!: string
                        port!:  int
                    }
                }
                
                // Built-in monitoring sidecar
                monitoring: #Container & {
                    #spec: image: "monitoring:latest"
                }
            }
        }
    }
    
    config: {
        image:    string
        port:     int & >0
        replicas: int & >=1
        
        // Platform fields baked in
        environment: string & =~"^(dev|staging|prod)$"
    }
    
    values: {
        port:        8080
        replicas:    3
        environment: "prod"
    }
}
```

## Extend vs Fork Decision Guide

| Requirement | Extend | Fork |
|-------------|--------|------|
| Add values/components | ✅ Preferred | ⚠️ Overkill |
| Override values | ✅ Preferred | ⚠️ Overkill |
| Apply platform policies | ✅ Preferred | ⚠️ Overkill |
| Change component structure | ❌ Not possible | ✅ Required |
| Remove components | ❌ Not possible | ✅ Required |
| Track upstream updates | ✅ Automatic | ⚠️ Manual merge |
| Maintenance burden | ✅ Low | ⚠️ High |
| Diverge from upstream | ❌ Limited | ✅ Full control |

**Rule of Thumb**: Use **Extend** for 90% of cases. Only **Fork** when structural changes are absolutely required.

## Functional Requirements

- **FR-MC-001**: Platform Operators MUST be able to extend upstream modules via CUE import and unification
- **FR-MC-002**: Extended modules MUST support adding new `config` fields, `values`, `#components`, and `#scopes`
- **FR-MC-003**: Extended modules MUST preserve upstream module metadata and attribution
- **FR-MC-004**: Platform Operators MUST be able to fork upstream modules via git fork
- **FR-MC-005**: Forked modules MUST be publishable to catalog with clear version indication
- **FR-MC-006**: CLI MUST provide guidance on extend vs fork pattern selection
- **FR-MC-007**: Overlay files MUST merge in declared order
- **FR-MC-008**: Platform customizations MUST be visible in module inspection/diff

## CLI Integration

### Extend Pattern Commands

```bash
# Import upstream module
opm module import example.com/modules/webapp@v1 \
  --output ./modules/webapp

# Add overlay file
opm module overlay add ./modules/webapp \
  --overlay platform-values.cue

# Validate extended module
opm module validate ./modules/webapp

# Show effective configuration (with overlays)
opm module render ./modules/webapp
```

### Fork Pattern Commands

```bash
# Fork module (CLI helper)
opm module fork https://github.com/upstream/webapp.git \
  --output ./modules/webapp-fork

# Sync upstream changes
cd ./modules/webapp-fork
opm module sync-upstream

# Publish forked module
opm module publish ./modules/webapp-fork \
  --registry oci://registry.example.com/modules
```

## Acceptance Criteria

1. **Given** an upstream module in an OCI registry
2. **When** Platform Operator imports and extends it with new values
3. **Then** the extended module validates and preserves upstream metadata

4. **Given** an extended module with overlay files
5. **When** Platform Operator adds it to catalog
6. **Then** overlays are applied in order when End User deploys

7. **Given** an upstream module requiring structural changes
8. **When** Platform Operator forks the repository
9. **Then** the forked module can be modified and published to catalog

## Edge Cases

| Case | Behavior |
|------|----------|
| Upstream module not found | Import fails with clear error |
| Extension conflicts with upstream | CUE unification error with details |
| Overlay doesn't satisfy config | Validation fails before catalog addition |
| Fork diverges significantly | Manual merge conflicts must be resolved |
| Multiple overlays conflict | Later overlay wins (deep merge) |

## Success Criteria

- **SC-MC-001**: Platform Operator can extend module without forking in 90% of cases
- **SC-MC-002**: Extended module preserves upstream update path
- **SC-MC-003**: Fork vs extend decision is clear from documentation and CLI guidance
- **SC-MC-004**: Platform customizations are visible in module inspection tools
