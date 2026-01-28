# Feature Specification: OPM Application Definitions

**Feature Branch**: `001-application-definitions-spec`  
**Created**: 2025-12-09  
**Updated**: 2026-01-28  
**Status**: Draft

## Overview

This specification defines the application-side definitions for Open Platform Model (OPM). These definitions enable developers and platform teams to describe applications once and deploy anywhere, separating what an application is (resources, traits, policies) from how it gets configured (values) and deployed (releases).

The application model encompasses:
- **Component definitions**: Resources, Traits, Blueprints, Policies
- **Composition**: Components, Scopes
- **Modules**: Module, CompiledModule, ModuleRelease
- **Distribution**: Bundles and multi-module stacks

For platform-specific transformation definitions (Provider, Transformer), see [016-platform-definitions-spec](../../platform-model/016-platform-definitions-spec/spec.md).

For details on lifecycle management, see the [OPM Lifecycle Specification](../010-definition-lifecycle-spec/spec.md).

## Design Principles

### Definition Types as Semantic Categories

OPM organizes definitions into semantic categories that help humans and tooling understand the role each definition plays:

| Type | Purpose | Question It Answers | Key Field/s | Utilised in |
|------|---------|---------------------|-----------|------------|
| **Resource** | What must exist | "What is being deployed?" | `#spec` | `Component` |
| **Trait** | How it behaves | "How does it operate?" | `appliesTo`, `#spec` | `Component` |
| **Blueprint** | How to compose it | "What does a common pattern look like?" | `composedResources`, `composedTraits` | `Component` |
| **Policy** | What must be true | "What rules must it follow?" | `target`, `enforcement` | `Scope` |

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

## Feature Availability

To minimize cognitive load for the initial release (CLI v1), some core definitions are specified but **deferred**. They are part of the OPM model but will be enabled in future releases.

| Definition | Status | Description |
|------------|--------|-------------|
| **#Resource** | **Enabled** | Core deployable unit |
| **#Trait** | **Enabled** | Behavior modifier |
| **#Blueprint** | **Enabled** | Reusable composition pattern |
| **#Component** | **Enabled** | Logical application part |
| **#Module** | **Enabled** | Portable application package |
| **#Provider** | **Enabled** | Platform adapter |
| **#Transformer** | **Enabled** | Resource transformation logic |
| **#Template** | **Enabled** | Module initialization template |
| **#Interface** | Deferred | Module interface contracts |
| **#Lifecycle** | Deferred | Transition-time operations |
| **#Policy** | Deferred | Governance constraint |
| **#Scope** | Deferred | Policy applicator |
| **#Status** | Deferred | Health and state reporting |
| **#Bundle** | Deferred | Multi-module application stack |

## Clarifications

### Session 2025-12-10

- Q: What distinguishes a Trait from a Policy? → A: **Semantic purpose and enforcement**. Traits configure behavior ("run 3 replicas"). Policies enforce constraints ("must not run as root"). Policies have `enforcement` settings (mode, onViolation) while Traits do not.
- Q: What are the policy levels? → A: **Scope** (cross-cutting across components).
- Q: Should Policies have `appliesTo` like Traits? → A: No. Traits declare Resource compatibility via `appliesTo`. Policies declare application level via `target` (component or scope). They serve different purposes.
- Q: How do transformers match components? → A: **Label-based matching**. Transformers declare `requiredLabels` that components must have. Component labels are the union of labels from the component itself plus all attached `#resources` and `#traits`. Example: `#Container` component wrapper requires `workload-type` label, so users must specify "stateless" or "stateful", which transformers then match against.
- Q: What happens when multiple transformers match? → A: If they have **identical requirements** (same requiredLabels + requiredResources + requiredTraits), it's an error. If they have **different requirements** (e.g., one requires Expose trait, one doesn't), they are complementary and both execute.
- Q: What about the Module naming collision? → A: `#Module` is the CUE definition for the portable application blueprint. `#CompiledModule` is the compiled/flattened form. "Module package" refers to the file system structure.

### Session 2026-01-26

- Q: When are policies enforced? → A: Runtime only (controller/provider enforcement after deployment).

## User Scenarios

### User Story 1 - Define Application Components (Priority: P1)

A developer defines an application module by declaring components with resources and traits. The OPM CUE schema validates the structure at evaluation time.

See [Module Component Subspec](./subspecs/component.md) for acceptance criteria.

---

### User Story 2 - Apply Governance via Policies (Priority: P1)

A platform team applies governance rules using Policies via scopes, including module-wide scopes.
Policies are enforced at runtime by controllers/providers; schema-time validation does not enforce policy behavior.

See [Policy Definition Specification](./subspecs/policy.md) for acceptance criteria.

---

### User Story 3 - Use Blueprints for Common Patterns (Priority: P2)

A developer uses Blueprints to quickly compose components following organizational best practices.

See [Blueprint Definition Specification](./subspecs/blueprint.md) for acceptance criteria.

---

### User Story 4 - Configure Module with Values (Priority: P2)

A developer provides defaults in `values.cue`, platform teams lock certain values, end-users customize the rest.

See [Module Definition Subspec](./subspecs/module-definition.md) for acceptance criteria.

---

### User Story 5 - Deploy via ModuleRelease (Priority: P2)

A deployment system creates a ModuleRelease with concrete values targeting a specific environment.

See [Module Definition Subspec](./subspecs/module-definition.md) for acceptance criteria.

---

### User Story 6 - Transform to Platform Resources (Priority: P3)

A provider transforms OPM components into platform-specific resources (e.g., Kubernetes Deployments). Transformers use label-based matching to determine which components they can handle. Component labels are inherited from attached resources and traits.

See [Transformer Subspec](./subspecs/transformer.md) for acceptance criteria.

---

### User Story 7 - Define Module Status (Priority: P3)

A developer defines status for a Module to expose health indicators, diagnostic details, and human-readable messages computed from configuration.

See [Status Definition Specification](./subspecs/status.md) for acceptance criteria.

---

### User Story 10 - Composable Governance (Priority: P2)

A platform engineer enforces both cost and security guardrails across multiple components without developer intervention, using multiple Scopes with different selectors.

**Acceptance Scenarios**:

1. **Given** a Module with `api` and `worker` components.
2. **When** a `PlatformCost` Scope applies a `ResourceQuota` policy to all components via `appliesTo.components: #allComponentsList`.
3. **And** a `PlatformSecurity` Scope applies an `mTLS` policy only to components with `metadata.labels.tier: "backend"`.
4. **Then** the `api` component (labeled `tier: "backend"`) receives both `ResourceQuota` and `mTLS` policies.
5. **And** the `worker` component (without the label) receives only the `ResourceQuota` policy.

See [Scope Definition Specification](./subspecs/scope.md) and [Policy Definition Specification](./subspecs/policy.md) for details.

---

### User Story 12 - Custom Runtime Health Probes (Priority: P3)

An application developer defines application-specific health status that goes beyond simple readiness checks, using custom probe logic evaluated at runtime.

**Acceptance Scenarios**:

1. **Given** a Module with `api`, `worker`, and `cache` components.
2. **When** the Module's `#status.#probes` defines a custom probe named `endToEndHealth`.
3. **And** the probe logic checks `context.outputs.api.status.readyReplicas > 0` AND `context.outputs.worker.status.jobQueueLength < 100`.
4. **Then** the controller evaluates this probe at runtime by injecting live component state.
5. **And** the module becomes unhealthy if the job queue exceeds the threshold, even if all pods are "ready".

See [Status Definition Specification](./subspecs/status.md) for details.

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

See [Blueprint Definition Specification](./subspecs/blueprint.md) for details.

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

### Labels and Annotations

- **FR-045**: `#LabelsAnnotationsType` supports `string | int | bool | [string | int | bool]` values to enable both simple and array-based label/annotation values.

## Key Entities

### Component Definition Types (Building Blocks)

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Resource` | Deployable unit | `#spec` |
| `#Trait` | Behavior modifier | `appliesTo`, `#spec` |
| `#Blueprint` | Reusable pattern | `composedResources`, `composedTraits`, `#spec` |

### Composition Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Component` | Logical app part | `#resources`, `#traits`, `#blueprints`, `spec` |
| `#Scope` | Policy applicator | `#policies`, `appliesTo`, `spec` |

### Module Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Module` | Portable blueprint | `#components`, `#scopes`, `config`, `values` |
| `#CompiledModule` | Compiled form | Expanded blueprints, `#spec`, `values`, `#status` |
| `#ModuleRelease` | Deployment instance | `#module`, `values`, `namespace` |

### Bundle Types

| Entity | Purpose |
|--------|---------|
| `#Bundle` | Module collection |
| `#CompiledBundle` | Compiled bundle |
| `#BundleRelease` | Bundle deployment |

### Template Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
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
| Template | `core/v0/template.cue` |
| Common Types | `core/v0/common.cue` |

**Note**: Platform-specific definitions (Provider, Transformer) are defined in [016-platform-definitions-spec](../../platform-model/016-platform-definitions-spec/spec.md).

## Subspec Index

| Index | Subspec | Document | FR Range | Description |
|---|---|---|---|---|
| 1 | Resource | [Resource Definition](./subspecs/resource.md) | FR-1-001 to FR-1-008 | Definition of fundamental deployable units |
| 2 | Trait | [Trait Definition](./subspecs/trait.md) | FR-2-001 to FR-2-007 | Definition of behavior modifiers |
| 3 | Blueprint | [Blueprint Definition](./subspecs/blueprint.md) | FR-3-001 to FR-3-006 | Schema and behavior of reusable Blueprints |
| 5 | Module Definition | [module-definition.md](./subspecs/module-definition.md) | FR-5-001 to FR-5-007 | Defines the `#Module`, `#CompiledModule`, and `#ModuleRelease` entities |
| 6 | Component | [component.md](./subspecs/component.md) | FR-6-001 to FR-6-009 | Component composition within modules |
| 7 | Interface | [interface.md](./subspecs/interface.md) | FR-094 to FR-110 | Module interface contracts |
| 8 | Scope | [Scope Definition](./subspecs/scope.md) | FR-8-001 to FR-8-006 | Scope-level policy application |
| 9 | Policy | [Policy Definition](./subspecs/policy.md) | FR-9-001 to FR-9-007 | Policy system for scope-level governance |
| 10 | Status | [Status Definition](./subspecs/status.md) | FR-10-001 to FR-10-007 | Computed status from module configuration |
| 11 | Lifecycle System | [lifecycle.md](./subspecs/lifecycle.md) | FR-4-001 to FR-11-007 | Lifecycle overview and subsystem context |
| 12 | Bundle Definition | [bundle-definition.md](./subspecs/bundle-definition.md) | FR-12-001 to FR-12-004 | Aggregation of modules into bundles |

## Related Specifications

- [016-platform-definitions-spec](../../platform-model/016-platform-definitions-spec/spec.md) - Platform Provider and Transformer definitions
- [013-cli-render-spec](../013-cli-render-spec/spec.md) - CLI render system using these definitions
