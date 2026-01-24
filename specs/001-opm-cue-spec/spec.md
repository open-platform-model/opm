# Feature Specification: OPM Core CUE Definition

**Feature Branch**: `001-opm-cue-spec`  
**Created**: 2025-12-09  
**Updated**: 2026-01-22  
**Status**: Draft

## Overview

This specification defines the core CUE schema for Open Platform Model (OPM). OPM uses typed definitions to express application structure, behavior, and governance in a portable, composable way.

For details on lifecycle management, see the [OPM Lifecycle Specification](../003-lifecycle-spec/spec.md).

## Design Principles

### Definition Types as Semantic Categories

OPM organizes definitions into semantic categories that help humans and tooling understand the role each definition plays:

| Type | Purpose | Question It Answers | Key Field/s | Utilised in |
|------|---------|---------------------|-----------|------------|
| **Resource** | What must exist | "What is being deployed?" | `#spec` | `Component` |
| **Trait** | How it behaves | "How does it operate?" | `appliesTo`, `#spec` | `Component` |
| **Blueprint** | How to compose it | "What does a common pattern look like?" | `composes` | `Component` |
| **Policy** | What must be true | "What rules must it follow?" | `target`, `enforcement` | `Scope`, `Module` |

The first three types form the foundation of component composition:

```text
Resource  = The deployable thing (Container, Volume, ConfigMap)
Trait     = Behavior/configuration of that thing (Replicas, HealthCheck, Expose)
Blueprint = Reusable pattern of the above (StatelessWorkload, StatefulWorkload)
```

### Naming Convention

All core definitions use short names without the "Definition" suffix:

- `#Resource` (not `#ResourceDefinition`)
- `#Trait` (not `#TraitDefinition`)
- `#Policy` (not `#PolicyDefinition`)
- `#Blueprint` (not `#BlueprintDefinition`)
- `#Component` (not `#ComponentDefinition`)
- `#Scope` (not `#ScopeDefinition`)
- `#Module` (not `#ModuleDefinition`)

## Clarifications

### Session 2025-12-10

- Q: What distinguishes a Trait from a Policy? → A: **Semantic purpose and enforcement**. Traits configure behavior ("run 3 replicas"). Policies enforce constraints ("must not run as root"). Policies have `enforcement` settings (mode, onViolation) while Traits do not.
- Q: What are the policy levels? → A: **Scope** (cross-cutting across components), and **Module** (runtime enforcement via `#Module.#policies`).
- Q: Should Policies have `appliesTo` like Traits? → A: No. Traits declare Resource compatibility via `appliesTo`. Policies declare application level via `target` (component or scope). They serve different purposes.
- Q: How do transformers match components? → A: **Label-based matching**. Transformers declare `requiredLabels` that components must have. Component labels are the union of labels from the component itself plus all attached `#resources` and `#traits`. Example: `#Container` component wrapper requires `workload-type` label, so users must specify "stateless" or "stateful", which transformers then match against.
- Q: What happens when multiple transformers match? → A: If they have **identical requirements** (same requiredLabels + requiredResources + requiredTraits + requiredPolicies), it's an error. If they have **different requirements** (e.g., one requires Expose trait, one doesn't), they are complementary and both execute.

- Q: What about the Module naming collision? → A: `#Module` is the CUE definition for the portable application blueprint. `#ModuleCompiled` is the compiled/flattened form. "Module package" refers to the file system structure.

## User Scenarios

### User Story 1 - Define Application Components (Priority: P1)

A developer defines an application module by declaring components with resources and traits. The OPM CUE schema validates the structure at evaluation time.

See [Module Component Subspec](./subspecs/module-component.md) for acceptance criteria.

---

### User Story 2 - Apply Governance via Policies (Priority: P1)

A platform team applies governance rules using Policies at scope or module levels.

See [Module Policy Subspec](./subspecs/module-policy.md) for acceptance criteria.

---

### User Story 3 - Use Blueprints for Common Patterns (Priority: P2)

A developer uses Blueprints to quickly compose components following organizational best practices.

See [Component Blueprint Subspec](./subspecs/component-blueprint.md) for acceptance criteria.

---

### User Story 4 - Configure Module with Values (Priority: P2)

A developer provides defaults in `values.cue`, platform teams lock certain values, end-users customize the rest.

See [Module Values Subspec](./subspecs/module-values.md) for acceptance criteria.

---

### User Story 5 - Deploy via ModuleRelease (Priority: P2)

A deployment system creates a ModuleRelease with concrete values targeting a specific environment.

See [Module Definition Subspec](./subspecs/module-definition.md) for acceptance criteria.

---

### User Story 6 - Transform to Platform Resources (Priority: P3)

A provider transforms OPM components into platform-specific resources (e.g., Kubernetes Deployments). Transformers use label-based matching to determine which components they can handle. Component labels are inherited from attached resources and traits.

See [Transformer Matching Subspec](./subspecs/transformer-matching.md) for acceptance criteria.

---

### User Story 7 - Define Module Status (Priority: P3)

A developer defines status for a Module to expose health indicators, diagnostic details, and human-readable messages computed from configuration.

See [Module Status Subspec](./subspecs/module-status.md) for acceptance criteria.

---


### User Story 10 - Composable Governance (Priority: P2)

A platform engineer enforces both cost and security guardrails across multiple components without developer intervention, using multiple Scopes with different selectors.

**Acceptance Scenarios**:

1. **Given** a Module with `api` and `worker` components.
2. **When** a `PlatformCost` Scope applies a `ResourceQuota` policy to all components via `appliesTo.components: #allComponentsList`.
3. **And** a `PlatformSecurity` Scope applies an `mTLS` policy only to components with `metadata.labels.tier: "backend"`.
4. **Then** the `api` component (labeled `tier: "backend"`) receives both `ResourceQuota` and `mTLS` policies.
5. **And** the `worker` component (without the label) receives only the `ResourceQuota` policy.

See [Module Scope Subspec](./subspecs/module-scope.md) and [Module Policy Subspec](./subspecs/module-policy.md) for details.

---


### User Story 12 - Custom Runtime Health Probes (Priority: P3)

An application developer defines application-specific health status that goes beyond simple readiness checks, using custom probe logic evaluated at runtime.

**Acceptance Scenarios**:

1. **Given** a Module with `api`, `worker`, and `cache` components.
2. **When** the Module's `#status.#probes` defines a custom probe named `endToEndHealth`.
3. **And** the probe logic checks `context.outputs.api.status.readyReplicas > 0` AND `context.outputs.worker.status.jobQueueLength < 100`.
4. **Then** the controller evaluates this probe at runtime by injecting live component state.
5. **And** the module becomes unhealthy if the job queue exceeds the threshold, even if all pods are "ready".

See [Module Status Subspec](./subspecs/module-status.md) for details.

---

### User Story 13 - Golden Path Blueprints (Priority: P2)

A platform engineer creates a "golden path" for stateless web services, bundling resources, traits, and policies into a single abstraction that developers can easily adopt.

**Acceptance Scenarios**:

1. **Given** a `StandardWebService` Blueprint that composes:
   - **Resources**: `#Container`
   - **Traits**: `#Replicas`, `#Expose`, `#HealthCheck`
2. **When** an application developer uses this blueprint in a component.
3. **Then** the component automatically inherits spec fields for `container`, `replicas`, `expose`, and `healthCheck`.
4. **And** the developer only needs to provide values for the composed specs.
5. **And** if the developer provides conflicting values, CUE validation fails with a clear error.

See [Component Blueprint Subspec](./subspecs/component-blueprint.md) for details.

---

### User Story 14 - Multi-Module Application Stacks (Priority: P3)

An application developer assembles a full application stack by composing multiple independent modules into a single deployable Bundle.

**Acceptance Scenarios**:

1. **Given** a `#Bundle` definition named `WebAppStack`.
2. **When** its `#modules` field includes a `frontend` module and a `backend` module.
3. **And** the bundle exposes a top-level `#spec` for shared configuration like `domainName` and `environment`.
4. **Then** a `#BundleRelease` can provide a single set of `values` that configure both modules.
5. **And** the platform deploys and manages the entire stack as a single entity.

See [Bundle Definition Subspec](./subspecs/bundle-definition.md) for details.

## Core Conventions

### Naming and Identification

- **FR-026**: `#FQNType` format: `<repo-path>@v<major>#<Name>` (e.g., `opm.dev/resources/workload@v0#Container`).
- **FR-027**: `#VersionType` validates semantic versioning (major.minor.patch with optional prerelease/build).
- **FR-028**: `#NameType` is a string between 1-254 characters.
- **FR-029**: All definitions MUST have a computed `fqn` field: `"\(metadata.apiVersion)#\(metadata.name)"`.

### Validation and Type Safety

- **FR-043**: All definition `#spec` fields MUST be OpenAPIv3 compatible.
- **FR-044**: Definition structs MUST use `close({})` to prevent unspecified fields.

## Key Entities

### Component Definition Types (Building Blocks)

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Resource` | Deployable unit | `#spec`, `#defaults` |
| `#Trait` | Behavior modifier | `appliesTo`, `#spec`, `#defaults` |
| `#Blueprint` | Reusable pattern | `composedResources`, `composedTraits`, `#spec` |

### Composition Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Component` | Logical app part | `#resources`, `#traits`, `#blueprints`, `spec` |
| `#Scope` | Policy applicator | `#policies`, `appliesTo`, `spec` |

### Module Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Module` | Portable blueprint | `#components`, `#scopes`, `#policies`, `#values`, `#status`, `#interfaces` (or `#provides`, `#consumes`) |
| `#ModuleCompiled` | Compiled form | Expanded blueprints, resolved defaults |
| `#ModuleRelease` | Deployment instance | `module`, `values`, `namespace` |
| `#ModuleStatus` | Status schema | `healthy`, `message`, `details`, `phase` |

### Bundle Types

| Entity | Purpose |
|--------|---------|
| `#Bundle` | Module collection |
| `#BundleCompiled` | Compiled bundle |
| `#BundleRelease` | Bundle deployment |

### Platform Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Provider` | Platform adapter with transformer registry | `transformers`, `#declaredResources`, `#declaredTraits`, `#declaredPolicies` |
| `#Transformer` | Converts components to platform resources | `requiredLabels`, `requiredResources`, `optionalResources`, `requiredTraits`, `optionalTraits`, `requiredPolicies`, `optionalPolicies`, `#transform` |
| `#Renderer` | Outputs final manifests | `format` (yaml/json/toml/hcl) |
| `#Template` | Module initialization template | `category`, `level` |

## Schema References

All schemas are the authoritative specification:

| Definition | Path |
|------------|------|
| Module | `core/v0/module.cue` |
| ModuleCompiled | `core/v0/module_compiled.cue` |
| ModuleRelease | `core/v0/module_release.cue` |
| Bundle | `core/v0/bundle.cue` |
| BundleCompiled | `core/v0/bundle_compiled.cue` |
| BundleRelease | `core/v0/bundle_release.cue` |
| Component | `core/v0/component.cue` |
| Scope | `core/v0/scope.cue` |
| Resource | `core/v0/resource.cue` |
| Trait | `core/v0/trait.cue` |
| Policy | `core/v0/policy.cue` |
| Blueprint | `core/v0/blueprint.cue` |
| Provider | `core/v0/provider.cue` |
| Transformer | `core/v0/transformer.cue` |
| Renderer | `core/v0/renderer.cue` |
| Template | `core/v0/template.cue` |
| Common Types | `core/v0/common.cue` |

## Subspec Index

| Index | Subspec | Document | FR Range | Description |
|---|---|---|---|---|
| 1 | Component Resource | [component-resource.md](./subspecs/component-resource.md) | FR-1-001 to FR-1-008 | Definition of fundamental deployable units |
| 2 | Component Trait | [component-trait.md](./subspecs/component-trait.md) | FR-2-001 to FR-2-007 | Definition of behavior modifiers |
| 3 | Component Blueprint | [component-blueprint.md](./subspecs/component-blueprint.md) | FR-3-001 to FR-3-006 | Schema and behavior of reusable Blueprints |
| 5 | Module Definition | [module-definition.md](./subspecs/module-definition.md) | FR-5-001 to FR-5-007 | Defines the `#Module`, `#ModuleCompiled`, and `#ModuleRelease` entities |
| 6 | Module Component | [module-component.md](./subspecs/module-component.md) | FR-6-001 to FR-6-009 | Component composition within modules |
| 7 | Module Values | [module-values.md](./subspecs/module-values.md) | FR-7-001 to FR-7-006 | Configuration schema and value hierarchy |
| 8 | Module Scope | [module-scope.md](./subspecs/module-scope.md) | FR-8-001 to FR-8-006 | Scope-level policy application |
| 9 | Module Policy | [module-policy.md](./subspecs/module-policy.md) | FR-9-001 to FR-9-007 | Policy system across all levels |
| 10 | Module Status | [module-status.md](./subspecs/module-status.md) | FR-10-001 to FR-10-007 | Computed status from module configuration |
| 12 | Bundle Definition | [bundle-definition.md](./subspecs/bundle-definition.md) | FR-12-001 to FR-12-004 | Aggregation of modules into bundles |
| 13 | Platform Provider | [platform-provider.md](./subspecs/platform-provider.md) | FR-13-001 to FR-13-005 | Provider and Transformer structure |
| 14 | Transformer Matching | [transformer-matching.md](./subspecs/transformer-matching.md) | FR-14-001 to FR-14-007 | Label-based matching algorithm for transformers |
