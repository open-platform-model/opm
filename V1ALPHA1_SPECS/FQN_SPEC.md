# OPM Fully Qualified Name (FQN) Specification v1

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** 2025-10-31

## Overview

This document specifies the Fully Qualified Name (FQN) format for Open Platform Model (OPM) objects. The FQN provides a globally unique identifier that maps directly to CUE's module system.

**Applies to all OPM objects:** Unit, Trait, Blueprint, Component, Policy, Scope, Module, ModuleDefinition, ModuleRelease, and any other OPM object types.

---

## Hybrid Structure: Root vs Metadata apiVersion

OPM uses a **hybrid approach** for definition structure that separates concerns between OPM core versioning and element-specific versioning:

### Root Level (Fixed)

All OPM definitions have fixed root-level fields for OPM core API versioning:

```cue
apiVersion: "opm.dev/v1/core"  // Fixed for all v1 definitions
kind:       string              // "Unit", "Trait", "Blueprint", "Policy", "Module", etc.
```

These fields identify that an object is an OPM v1 definition and what type of definition it is.

### Metadata Level (Element-Specific)

**Definition types** (UnitDefinition, TraitDefinition, BlueprintDefinition, PolicyDefinition, ModuleDefinition, Module) have element-specific versioning in metadata:

```cue
metadata: {
    apiVersion!: string  // Element-specific version path (e.g., "opm.dev/units/workload@v1")
    name!:       string  // Element name (e.g., "Container")
    fqn:         string  // Computed as "\(apiVersion)#\(name)"
}
```

**Instance types** (ComponentDefinition, ScopeDefinition, ModuleRelease) do NOT have `metadata.apiVersion` or `metadata.fqn` - they only have `metadata.name` for instance identification.

### Why the Hybrid Approach?

1. **Kubernetes Compatibility**: Root-level `apiVersion` and `kind` match Kubernetes manifest structure
2. **Separation of Concerns**: OPM core versioning is separate from element/module versioning
3. **Clean Exports**: When exported to YAML/JSON, definitions look like standard Kubernetes resources
4. **Flexible Versioning**: Elements can version independently from the core schema

### Example: UnitDefinition

```cue
#Container: #UnitDefinition & {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"
    kind:       "Unit"

    // Metadata level: Element-specific versioning
    metadata: {
        apiVersion: "opm.dev/units/workload@v1"
        name:       "Container"
        fqn:        "opm.dev/units/workload@v1#Container"  // Computed from above
        description: "Container unit for workload definitions"
    }

    spec: {
        image!: string
        // ... container spec
    }
}
```

**Exported YAML** (root-level fields only):

```yaml
apiVersion: opm.dev/core/v1
kind: Unit
metadata:
  apiVersion: opm.dev/units/workload@v1
  name: Container
  fqn: opm.dev/units/workload@v1#Container
  description: Container unit for workload definitions
spec:
  image: nginx:latest
```

---

## FQN Format

```text
<repo-path>@v<major>#<Name>
```

### Components

**1. Repo Path** (Required)

- GitHub repository path, OCI registry path, or vanity domain
- Corresponds to CUE module path (without version)
- Examples: `opm.dev/units/workload`, `github.com/myorg/blueprints`, `acme.com/platform/traits`

**2. Version** (Required)

- Major version using semantic versioning
- Format: `@v0`, `@v1`, `@v2`, etc.
- Uses CUE's version suffix convention
- Only major version appears in FQN

**3. Name** (Required)

- PascalCase object name
- Uses CUE's definition prefix convention: `#Name`
- Must start with uppercase letter after `#`
- Alphanumeric only (no special characters except numbers)

---

## Examples

### Official OPM Objects

**Core Objects:**

```text
opm.dev/core/unit@v1#UnitDefinition
opm.dev/core/trait@v1#TraitDefinition
opm.dev/core/blueprint@v1#BlueprintDefinition
opm.dev/core/component@v1#ComponentDefinition
opm.dev/core/policy@v1#PolicyDefinition
opm.dev/core/scope@v1#ScopeDefinition
opm.dev/core/module@v1#ModuleDefinition
opm.dev/core/module@v1#Module
opm.dev/core/module@v1#ModuleRelease
```

**Units:**

```text
opm.dev/units/workload@v1#Container
opm.dev/units/storage@v1#Volume
opm.dev/units/config@v1#ConfigMap
opm.dev/units/config@v1#Secret
```

**Traits:**

```text
opm.dev/traits/scaling@v1#Replicas
opm.dev/traits/network@v1#Expose
opm.dev/traits/health@v1#HealthCheck
opm.dev/traits/security@v1#TLS
```

**Blueprints:**

```text
opm.dev/blueprints/workload@v1#StatelessWorkload
opm.dev/blueprints/workload@v1#StatefulWorkload
opm.dev/blueprints/workload@v1#DaemonWorkload
opm.dev/blueprints/workload@v1#TaskWorkload
```

**Modules:**

```text
opm.dev/modules@v1#WebApp
opm.dev/modules@v1#ThreeTierApp
opm.dev/modules@v1#Microservice
```

**Components:**

```text
opm.dev/components@v1#Frontend
opm.dev/components@v1#Backend
```

### Third-Party Objects

**GitHub-hosted:**

```text
github.com/myorg/blueprints@v1#CustomWorkload
github.com/myorg/modules@v2#EnterpriseApp
github.com/myorg/units@v1#AcmeDatabase
```

**GitLab-hosted:**

```text
gitlab.com/company/opm-units@v1#CustomUnit
gitlab.com/company/opm-modules@v1#StandardApp
```

### Corporate/Private Objects

**Private domains:**

```text
acme.com/platform/units@v1#AcmeContainer
internal.corp.net/devops/blueprints@v1#CorpMonitoring
enterprise.example/modules@v2#LegacyApp
```

---

## Direct CUE Mapping

The FQN format is designed to map **directly** to CUE's module and definition system.

### Mapping Structure

**FQN:**

```text
opm.dev/units/workload@v1#Container
```

**Breakdown:**

- Repo Path: `opm.dev/units/workload`
- Version: `@v1`
- Name: `#Container`

**CUE Module Path:**

```text
opm.dev/units/workload@v1
```

**CUE Import & Usage:**

```cue
import units "opm.dev/units/workload@v1"

container: units.#Container
```

### Comparison Table

| FQN Component | CUE Component | Example |
|---------------|---------------|---------|
| Repo Path | Module path | `opm.dev/units/workload` |
| `@v<major>` | Version suffix | `@v1` |
| `#<Name>` | Definition | `#Container` |
| **Full FQN** | Import path + Definition | `units.#Container` |

### Complete Mapping Example

```text
FQN:     opm.dev/units/workload@v1#Container
         └────────┬────────────┘└┬┘└───┬────┘
             repo path           @v   #Name

CUE Module:
module: "opm.dev/units/workload@v1"
        └────────┬────────────┘└┬┘
            repo path           @v

CUE Import:
import units "opm.dev/units/workload@v1"
              └──────────┬───────────────┘
                    module path

CUE Usage:
container: units.#Container
           └┬─┘└───┬────┘
          alias  definition
```

---

## Uniqueness Guarantee

Global uniqueness is ensured through a three-level hierarchy:

**1. Repo Path Level**: Domain + repository ownership

- `opm.dev/units/workload` → Controlled by OPM project
- `github.com/myorg/units` → GitHub username uniqueness
- `acme.com/platform/blueprints` → DNS domain ownership

**2. Version Level**: Major version for breaking changes

- `@v0` → Initial development, unstable API
- `@v1` → Stable API, backward compatible within v1
- `@v2` → Breaking changes from v1

**3. Name Level**: Object name uniqueness within repo + version

- `#Container` → Unique within `opm.dev/units/workload@v1`
- `#StatelessWorkload` → Unique within `opm.dev/blueprints/workload@v1`

### Collision Prevention

**Different repositories can use the same name without collision:**

```text
opm.dev/units/data@v1#Database
github.com/myorg/units@v1#Database         ← Different repo, no collision
acme.com/platform/units@v1#Database        ← Different repo, no collision
```

**Same repository can use same name in different versions:**

```text
opm.dev/blueprints/workload@v0#Workload
opm.dev/blueprints/workload@v1#Workload    ← Different version, breaking changes allowed
```

---

## Validation Rules

### Repo Path Validation

**Pattern:** `[a-z0-9.-]+(?:/[a-z0-9.-]+)+`

**Rules:**

- Must be a valid domain + at least one path segment
- Lowercase letters, numbers, dots, hyphens only
- At least one `/` separator (domain/repo structure)
- Must be owned/controlled by publisher

**Examples:**

- `opm.dev/units/workload` ✅
- `github.com/myorg/blueprints` ✅
- `acme.com/platform/units` ✅
- `opm.dev` ❌ (missing path segment)
- `OPM.dev/units` ❌ (uppercase not allowed)

**Reserved Repo Paths:**

- `opm.dev/*` - Reserved for official OPM projects
- Common official repos:
  - `opm.dev/core/*` - Core OPM schema (unit, trait, blueprint, component, module, policy, scope)
  - `opm.dev/units/*` - Official unit catalog (workload, storage, config, network)
  - `opm.dev/traits/*` - Official trait catalog (scaling, health, network, security)
  - `opm.dev/blueprints/*` - Official blueprint catalog (workload patterns)
  - `opm.dev/modules/*` - Official module catalog

**Recommended:**

- Use `github.com/<username>/<repo>` for open source
- Use `gitlab.com/<username>/<repo>` for GitLab-hosted
- Use your own domain for corporate/private

### Version Validation

**Pattern:** `@v[0-9]+`

**Rules:**

- Must start with `@v`
- Followed by one or more digits (major version only)
- Examples: `@v0`, `@v1`, `@v2`, `@v10`

**Semantics:**

- `@v0` - Initial development, API may be unstable
- `@v1+` - Stable API, semantic versioning applies
- New major version for breaking changes

**Examples:**

- `@v0` ✅
- `@v1` ✅
- `@v42` ✅
- `@v1.2.3` ❌ (only major version in FQN)
- `@1` ❌ (missing `v` prefix)
- `v1` ❌ (missing `@` symbol)

### Name Validation

**Pattern:** `#[A-Z][a-zA-Z0-9]*`

**Rules:**

- Must start with `#` followed by uppercase letter
- PascalCase required
- Alphanumeric characters only after `#`
- Must be unique within repo path + version scope
- Should be descriptive, not abbreviated

**Examples:**

- `#Container` ✅
- `#StatelessWorkload` ✅
- `#ConfigMap` ✅
- `#MyCustomElement` ✅
- `#container` ❌ (must start with uppercase after #)
- `#Stateless-Workload` ❌ (no hyphens)
- `#SWL` ❌ (too abbreviated)
- `Container` ❌ (missing # prefix)

### Complete FQN Pattern

**Regular Expression:**

```regex
^([a-z0-9.-]+(?:/[a-z0-9.-]+)+)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$
```

**Capture Groups:**

1. Repo path (domain + path segments)
2. Major version number
3. Name (without # prefix)

### Validation Examples

| FQN | Valid | Reason |
|-----|-------|--------|
| `opm.dev/units/workload@v1#Container` | ✅ | Correct format |
| `github.com/myorg/blueprints@v1#Custom` | ✅ | Correct format |
| `acme.com/platform/units@v2#Database` | ✅ | Multi-level repo path |
| `opm.dev@v1#Container` | ❌ | Missing repo path segment |
| `opm.dev/units@1#Container` | ❌ | Missing `v` in version |
| `opm.dev/units@v1.2#Container` | ❌ | Minor version in FQN |
| `opm.dev/units@v1#container` | ❌ | Name not PascalCase |
| `opm.dev/units/v1#Container` | ❌ | Using `/` instead of `@` |

---

## Resolution Algorithm

Simple algorithm to resolve an FQN to a CUE definition:

### Step 1: Parse FQN

```text
Input: "opm.dev/units/workload@v1#Container"

Split on @ and #:
  - Repo path: "opm.dev/units/workload"
  - Version: "v1"
  - Name: "Container"
```

### Step 2: Construct CUE Module Path

```text
Module path = repo-path + "@" + version
            = "opm.dev/units/workload@v1"
```

### Step 3: Locate Module

```text
Check locations:
  - OCI registry: oci://registry.cue.works/opm.dev/units/workload@v1
  - Local cache:  ~/.cache/opm/modules/opm.dev/units/workload/v1
  - CUE modules:  $CUE_MODCACHE/opm.dev/units/workload@v1
```

### Step 4: Import & Reference

```cue
import units "opm.dev/units/workload@v1"

object: units.#Container
```

### Example Implementation

```go
func ResolveFQN(fqn string) (modulePath, name string, err error) {
    // Split on @
    parts := strings.Split(fqn, "@")
    if len(parts) != 2 {
        return "", "", errors.New("invalid FQN: missing @")
    }
    repoPath := parts[0]

    // Split on #
    versionParts := strings.Split(parts[1], "#")
    if len(versionParts) != 2 {
        return "", "", errors.New("invalid FQN: missing #")
    }
    version := versionParts[0]
    name := versionParts[1]

    // Construct module path
    modulePath = repoPath + "@" + version
    // "opm.dev/units/workload@v1"

    return modulePath, name, nil
}
```

---

## Versioning Strategy

### Major Versions in FQN

Major version changes indicate **breaking changes** to object schema or behavior.

**Version Progression:**

```text
opm.dev/units/workload@v0#Container  → Initial development
opm.dev/units/workload@v1#Container  → Stable release
opm.dev/units/workload@v2#Container  → Breaking changes
```

**Breaking changes include:**

- Removing or renaming required fields
- Changing field types incompatibly
- Changing object semantics or behavior
- Removing or changing validation constraints

### Minor/Patch Versions

Minor and patch versions are managed at the CUE module level, not in the FQN.

**In FQN:** Only major version

```text
opm.dev/units/workload@v1#Container
```

**In CUE module dependencies:** Full semantic version

```cue
// cue.mod/module.cue
module: "opm.dev/units/workload@v1"

deps: {
    "opm.dev/core/unit@v1": {
        v:       "v1.2.3"  // Full semver
        default: true
    }
}
```

**Version Semantics:**

- **Major** (`v0` → `v1`): Breaking changes, new FQN required
- **Minor** (`v1.0.0` → `v1.1.0`): New optional fields, backward-compatible additions
- **Patch** (`v1.0.0` → `v1.0.1`): Bug fixes, documentation, internal refactoring

---

## Repository Organization

The repo path provides flexibility in how you organize your OPM objects.

### Single Repository per Object Type

```text
opm.dev/core/unit@v1#UnitDefinition
opm.dev/core/component@v1#ComponentDefinition
opm.dev/core/module@v1#ModuleDefinition

opm.dev/units/workload@v1#Container
opm.dev/blueprints/workload@v1#StatelessWorkload

opm.dev/modules@v1#WebApp
opm.dev/modules@v1#ThreeTierApp

Each is a separate repository with its own versioning.
```

### Hierarchical Repository Structure

```text
acme.com/platform/units@v1#CustomContainer
acme.com/platform/blueprints@v1#CustomWorkload

acme.com/platform/modules@v1#StandardApp
acme.com/platform/modules@v1#EnterpriseApp

Repository: github.com/acme/platform-units
Published as: acme.com/platform/units@v1

Repository: github.com/acme/platform-modules
Published as: acme.com/platform/modules@v1
```

### Monorepo with Logical Separation

```text
github.com/myorg/opm/units@v1#CustomUnit
github.com/myorg/opm/traits@v1#CustomTrait
github.com/myorg/opm/modules@v1#CustomModule

All objects in single repository: github.com/myorg/opm
Versioned together, published under different paths
```

---

## Vanity Domains

OPM supports vanity domains that redirect to actual repository locations.

### Vanity Domain Mapping

**Vanity FQN:**

```text
opm.dev/units/workload@v1#Container
```

**Resolves to:**

```text
github.com/open-platform-model/units-workload@v1#Container
```

**Configured in CUE Registry:**

```text
Registry mapping:
  opm.dev/units/workload → github.com/open-platform-model/units-workload

OCI path:
  oci://registry.cue.works/opm.dev/units/workload@v1
```

### Benefits

- **Shorter FQNs**: `opm.dev/units/workload@v1#Container` vs `github.com/open-platform-model/units-workload@v1#Container`
- **Repository independence**: Can move repos without changing FQNs
- **Branding**: Use your own domain for official objects

### Setting Up Vanity Domains

1. **Own the domain** (e.g., `opm.dev`)
2. **Configure CUE Central Registry** to map vanity domain to repo
3. **Publish modules** using vanity domain path
4. **Users resolve** automatically via registry

---

## Reserved Namespaces

### Reserved Repo Paths

The following repo paths are reserved for official OPM use:

- `opm.dev/core/*` - Core OPM schema (Unit, Trait, Blueprint, Component, Module, Policy, Scope)
- `opm.dev/units/*` - Official unit catalog
- `opm.dev/traits/*` - Official trait catalog
- `opm.dev/blueprints/*` - Official blueprint catalog
- `opm.dev/modules/*` - Official module catalog
- `opm.dev/*` - All paths under `opm.dev` reserved

### Third-Party Guidelines

For third-party objects:

✅ **Recommended:**

- Use GitHub: `github.com/<username>/<repo>@v1#Name`
- Use GitLab: `gitlab.com/<username>/<repo>@v1#Name`
- Use your domain: `acme.com/<repo>@v1#Name`

❌ **Not Allowed:**

- Using `opm.dev/*` paths without authorization
- Impersonating official OPM objects

✅ **Contributing to Official Catalogs:**

- Submit proposals to OPM project
- Follow contribution guidelines
- Objects will be published under `opm.dev/*`

---

## Summary

### Component Breakdown

- **Repo Path** - Domain + repository path
- **@v<major>** - Major version (CUE convention)
- **#<Name>** - Object name (CUE definition convention)

### Uniqueness Hierarchy

1. **Repo Path Level** - Domain + repository ownership
2. **Version Level** - Major version management
3. **Name Level** - Object name uniqueness

### CUE Mapping

```text
FQN:     opm.dev/units/workload@v1#Container
         └────────┬────────────┘└┬┘└───┬────┘
              repo path          @v  #Name

CUE:     import units "opm.dev/units/workload@v1"
                       └──────────┬───────────────┘
                             module path

         container: units.#Container
                    └┬─┘└───┬────┘
                  alias  definition
```

### Validation Patterns

- Repo Path: `[a-z0-9.-]+(?:/[a-z0-9.-]+)+`
- Version: `@v[0-9]+`
- Name: `#[A-Z][a-zA-Z0-9]*`

### Key Benefits

1. ✅ **Perfect CUE alignment** - Direct mapping to module system
2. ✅ **Simple and clean** - Only 3 components
3. ✅ **Industry standard** - Uses CUE's @ and # conventions
4. ✅ **Flexible** - Supports any repository organization
5. ✅ **Unambiguous** - Clear parsing and resolution

---

**Document Version:** 1.0.0-draft
**Date:** 2025-10-29
