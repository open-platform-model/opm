# Feature Specification: Platform Runtime & Module Catalog

**Feature Branch**: `015-platform-runtime-spec`  
**Created**: 2026-01-28  
**Status**: Draft  
**Input**: User description: "Create specification for tiered values system with Module Author defaults, Platform Operator overrides, and End User values, inspired by Timoni"

## Overview

This specification defines the OPM platform runtime system, focusing on how Platform Operators curate module catalogs and how values flow through a tiered overlay system from Module Author to Platform Operator to End User.

**Key Capabilities:**

- Platform Operators curate module catalogs with approved modules
- Module customization via extend (import+unify) or fork (git) patterns
- Tiered values system with overlay-based merging
- Registry-centric deployment model (End Users deploy from catalog only)

**Related Specifications:**

- [001-application-definitions-spec](../application-model/001-application-definitions-spec/spec.md) - Core OPM application definitions
- [016-platform-definitions-spec](./016-platform-definitions-spec/spec.md) - Platform definitions (Provider, Transformer)
- [002-cli-spec](../cli/002-cli-spec/spec.md) - CLI implementation
- [011-oci-distribution-spec](../cli/011-oci-distribution-spec/spec.md) - OCI distribution

## Design Principles

### 1. Registry-Centric Deployment

End Users can only deploy modules that exist in the `#ModuleCatalog`. This gives Platform Operators control over approved modules, versions, and configurations.

### 2. Overlay-Based Values

Values flow through tiers via overlay system (later layers win):

```text
Module Author → Platform Operator → End User
```

Platform Operators can:

- Use `*` for default values (End User can override)
- Use concrete values to lock configuration (End User cannot override)

### 3. Module Customization Patterns

Platform Operators have two customization approaches:

| Pattern | Method | Use Case |
|---------|--------|----------|
| **Extend** | Import module + CUE unification | Add values/components, minor changes |
| **Fork** | Git fork with direct edits | Structural changes, major customization |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Platform Operator Curates Module Catalog (Priority: P1)

A Platform Operator creates a `#ModuleCatalog` with approved modules for their organization.

**Why this priority**: Foundation for all platform runtime features. Without a catalog, there's no curation or governance.

**Independent Test**: Can create catalog, add modules via OCI reference or local path, verify catalog validates.

**Acceptance Scenarios**:

1. **Given** a Platform Operator has access to upstream OCI modules
2. **When** they create a `#ModuleCatalog` and include modules by reference
3. **Then** the catalog validates and modules are available for deployment

---

### User Story 2 - Platform Operator Extends Module with Overlays (Priority: P1)

A Platform Operator imports an upstream module and adds platform-specific configuration via overlays.

**Why this priority**: Core customization pattern. Enables platform governance without forking.

**Independent Test**: Import module, add overlay file with locked values, verify End User cannot override.

**Acceptance Scenarios**:

1. **Given** an upstream module `example.com/app@v1#WebApp` with `config.replicas: int`
2. **When** Platform Operator creates overlay: `values: replicas: 3` (concrete)
3. **Then** the module in catalog has `replicas: 3` locked
4. **And** End User attempting `replicas: 1` gets clear error message

---

### User Story 3 - End User Deploys from Catalog (Priority: P1)

An End User creates a `#ModuleRelease` referencing a module from the catalog.

**Why this priority**: Core deployment workflow. Validates the registry-centric model.

**Independent Test**: Create release with catalog module reference, provide values, verify deployment.

**Acceptance Scenarios**:

1. **Given** a `#ModuleCatalog` with module `web-app`
2. **When** End User creates `#ModuleRelease` with `module: "web-app"` and valid values
3. **Then** the deployment succeeds
4. **And** End User attempting to deploy non-catalog module gets error

---

### User Story 4 - Platform Operator Forks Module (Priority: P2)

A Platform Operator forks an upstream module for major customization.

**Why this priority**: Alternative customization pattern for complex scenarios. Less common than extend.

**Independent Test**: Fork module repo, make structural changes, include in catalog, verify deployment.

**Acceptance Scenarios**:

1. **Given** an upstream module with insufficient flexibility
2. **When** Platform Operator forks the module git repository
3. **And** makes structural changes to components
4. **Then** the forked module can be included in catalog
5. **And** End Users deploy the forked version

---

### Edge Cases

| Case | Behavior |
|------|----------|
| End User overrides locked value | Clear error: "Value 'replicas' is locked to 3 by Platform Operator" |
| Module not in catalog | Deployment blocked: "Module 'foo' not found in catalog" |
| Catalog module version mismatch | Error: "Module requires v1.2.3, catalog has v1.0.0" |
| Overlapping overlays | Later overlay wins (deep merge) |
| Invalid overlay (doesn't satisfy config) | Validation error at catalog inclusion time |

## Requirements

### Functional Requirements

- **FR-015-001**: `#ModuleCatalog` MUST contain a registry of approved modules
- **FR-015-002**: `#ModuleCatalog` MUST support OCI references and local paths for modules
- **FR-015-003**: Platform Operator MUST be able to add overlay files that merge with module values
- **FR-015-004**: Platform Operator MAY use `*` for default values (End User can override)
- **FR-015-005**: Platform Operator MAY use concrete values to lock configuration (End User cannot override)
- **FR-015-006**: End Users MUST only deploy modules that exist in the catalog
- **FR-015-007**: Values MUST merge via overlay system: Module Author → Platform Operator → End User
- **FR-015-008**: Value conflicts MUST produce clear error messages indicating the locked value and source tier
- **FR-015-009**: Platform Operator MUST be able to extend upstream modules via CUE import + unification
- **FR-015-010**: Platform Operator MUST be able to fork upstream modules via git fork
- **FR-015-011**: Multi-format value input MUST be supported (CUE, YAML, JSON) with conversion to CUE

### Key Entities

- **`#ModuleCatalog`**: Platform Operator's curated registry of approved modules
- **`#ModuleRelease`**: End User's deployment request (defined in [001-application-definitions-spec](../application-model/001-application-definitions-spec/spec.md))
- **Overlay files**: Value customization files at each tier (author, platform, user)

## Success Criteria

### Measurable Outcomes

- **SC-015-001**: Platform Operator can create catalog and add modules in under 5 minutes
- **SC-015-002**: End User attempting to override locked value receives actionable error message
- **SC-015-003**: Platform Operator can extend module without forking in 90% of customization scenarios
- **SC-015-004**: Value provenance is clear (who set which value) in error messages and tooling

## Subspec Index

| Index | Subspec | Document | Description |
|---|---|---|---|
| 1 | Module Catalog | [module-catalog.md](./subspecs/module-catalog.md) | `#ModuleCatalog` schema and behavior |
| 2 | Module Curation | [module-curation.md](./subspecs/module-curation.md) | Extend vs Fork patterns |
| 3 | Values Overlay | [values-overlay.md](./subspecs/values-overlay.md) | Tiered values with overlay system |

## Research

See [research.md](./research.md) for Timoni analysis and design decisions.

## Future Work (Deferred)

The following topics are recognized but deferred to future iterations:

- **Controller Architecture**: Kubernetes controller reconciliation loop
- **Policy Enforcement**: Runtime policy evaluation and violation handling
- **Status Probes**: Custom health checks evaluated at runtime
- **Multi-tenancy**: Namespace isolation and RBAC integration
- **Observability**: Metrics, tracing, audit logs
