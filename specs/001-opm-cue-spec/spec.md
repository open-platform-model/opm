# Feature Specification: OPM Core CUE Definition

**Feature Branch**: `001-opm-cue-spec`  
**Created**: 2025-12-09  
**Updated**: 2025-12-10  
**Status**: Draft

## Overview

This specification defines the core CUE schema for Open Platform Model (OPM). OPM uses typed definitions to express application structure, behavior, and governance in a portable, composable way.

## Design Principles

### Definition Types as Semantic Categories

OPM organizes definitions into semantic categories that help humans and tooling understand the role each definition plays:

| Type | Purpose | Question It Answers | Key Field |
|------|---------|---------------------|-----------|
| **Resource** | What must exist | "What is being deployed?" | `#spec` |
| **Trait** | How it behaves | "How does it operate?" | `appliesTo`, `#spec` |
| **Policy** | What must be true | "What rules must it follow?" | `target`, `enforcement` |

These three types form the foundation of component composition:

```
Resource  = The deployable thing (Container, Volume, ConfigMap)
Trait     = Behavior/configuration of that thing (Replicas, HealthCheck, Expose)
Policy    = Constraints on that thing (Encryption, NetworkRules, ResourceQuota)
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
- Q: What are the policy levels? → A: **Component** (intrinsic to one component), **Scope** (cross-cutting across components), and **Module** (runtime enforcement via `#Module.#policies`).
- Q: Should Policies have `appliesTo` like Traits? → A: No. Traits declare Resource compatibility via `appliesTo`. Policies declare application level via `target` (component or scope). They serve different purposes.
- Q: How do transformers match components? → A: **Label-based matching**. Transformers declare `requiredLabels` that components must have. Component labels are the union of labels from the component itself plus all attached `#resources`, `#traits`, and `#policies`. Example: `#Container` component wrapper requires `workload-type` label, so users must specify "stateless" or "stateful", which transformers then match against.
- Q: What happens when multiple transformers match? → A: If they have **identical requirements** (same requiredLabels + requiredResources + requiredTraits + requiredPolicies), it's an error. If they have **different requirements** (e.g., one requires Expose trait, one doesn't), they are complementary and both execute.

### Session 2025-12-09

- Q: What is the relationship between `#values` schema and `values.cue` file? → A: `#values` is a pure OpenAPIv3-compatible schema. `values.cue` contains concrete default values. Platform teams can override defaults; their values become immutable for end-users.
- Q: What about the Module naming collision? → A: `#Module` is the CUE definition for the portable application blueprint. `#ModuleCompiled` is the compiled/flattened form. "Module package" refers to the file system structure.

## User Scenarios & Testing

### User Story 1 - Define Application Components (Priority: P1)

A developer defines an application module by declaring components with resources, traits, and policies. The OPM CUE schema validates the structure at evaluation time.

**Acceptance Scenarios**:

1. **Given** a Module with a component containing a Container resource, **When** evaluated, **Then** validation succeeds.
2. **Given** a Module with an invalid FQN format, **When** evaluated, **Then** validation fails with a clear error.
3. **Given** a component with resources, traits, and policies, **When** evaluated, **Then** the component's `spec` field contains merged fields from all definitions.

---

### User Story 2 - Apply Governance via Policies (Priority: P1)

A platform team applies governance rules using Policies at component, scope, or module levels.

**Acceptance Scenarios**:

1. **Given** a Policy with `target: "component"`, **When** added to `#Component.#policies`, **Then** validation succeeds.
2. **Given** a Policy with `target: "scope"`, **When** added to `#Component.#policies`, **Then** validation fails (target mismatch).
3. **Given** a Policy with `target: "scope"`, **When** added to `#Scope.#policies`, **Then** validation succeeds.
4. **Given** a Policy with `enforcement.mode: "runtime"`, **When** added to `#Module.#policies`, **Then** it is recognized as a module-level runtime policy.

---

### User Story 3 - Use Blueprints for Common Patterns (Priority: P2)

A developer uses Blueprints to quickly compose components following organizational best practices.

**Acceptance Scenarios**:

1. **Given** a Blueprint composing Container + Replicas + HealthCheck, **When** used in a component, **Then** the component has access to all composed specs.
2. **Given** a component using a Blueprint, **When** evaluated, **Then** `#blueprints` map contains the Blueprint reference.

---

### User Story 4 - Configure Module with Values (Priority: P2)

A developer provides defaults in `values.cue`, platform teams lock certain values, end-users customize the rest.

**Acceptance Scenarios**:

1. **Given** a Module with `#values` schema and `values.cue` defaults, **When** no overrides provided, **Then** defaults are used.
2. **Given** a platform team locks `replicas: 3`, **When** an end-user sets `replicas: 1`, **Then** the validation fails with a clear error.
3. **Given** a module missing `values.cue`, **When** validated, **Then** validation fails.

---

### User Story 5 - Deploy via ModuleRelease (Priority: P2)

A deployment system creates a ModuleRelease with concrete values targeting a specific environment.

**Acceptance Scenarios**:

1. **Given** a Module with a required image tag in `#values`, **When** ModuleRelease provides a valid tag, **Then** validation succeeds.
2. **Given** a ModuleRelease missing required values, **When** evaluated, **Then** validation fails.

---

### User Story 6 - Transform to Platform Resources (Priority: P3)

A provider transforms OPM components into platform-specific resources (e.g., Kubernetes Deployments). Transformers use label-based matching to determine which components they can handle. Component labels are inherited from attached resources, traits, and policies.

See [Transformer Matching Subsystem](./subsystems/transformer-matching.md) for detailed matching algorithm, acceptance criteria, and examples.

---

### Edge Cases

- **Conflicting labels**: CUE unification fails automatically when resources/traits have conflicting labels.
- **Optional traits not provided**: Transformers use `#defaults` from the Trait definition.
- **Scope matches no components**: Valid but has no effect.
- **Platform-locked value override attempt**: CUE unification enforces immutability.

See [Transformer Matching Subsystem](./subsystems/transformer-matching.md) for transformer-specific edge cases.

## Requirements

### Definition Types

#### Resource

- **FR-001**: `#Resource` defines fundamental deployable units with an OpenAPIv3-compatible `#spec` schema.
- **FR-002**: Resources represent things that must exist in the runtime (Container, Volume, ConfigMap).
- **FR-003**: A component MUST have at least one Resource.

#### Trait

- **FR-004**: `#Trait` defines behavior modifiers with an `appliesTo` field referencing compatible Resources.
- **FR-005**: Traits MUST declare which Resources they can modify via `appliesTo: [...#Resource]`.
- **FR-006**: Traits are optional and configure "how" a Resource operates.

#### Policy

- **FR-007**: `#Policy` defines governance constraints with `enforcement` settings.
- **FR-008**: Policies MUST specify `target: "component" | "scope"` to control where they can be applied.
- **FR-009**: Policies MUST specify `enforcement.mode: "deployment" | "runtime" | "both"`.
- **FR-010**: Policies MUST specify `enforcement.onViolation: "block" | "warn" | "audit"`.
- **FR-011**: Policies MAY include `enforcement.platform` for platform-specific configuration (Kyverno, OPA, etc.).

**Policy Levels**:

| Level | Applied In | Use Case |
|-------|------------|----------|
| Component | `#Component.#policies` | Intrinsic constraints (SecurityContext, ResourceQuota) |
| Scope | `#Scope.#policies` | Cross-cutting constraints (NetworkRules, mTLS) |
| Module | `#Module.#policies` | Runtime enforcement (AuditLogging, PodDisruptionBudget) |

#### Blueprint

- **FR-012**: `#Blueprint` defines reusable compositions with `composedResources` and optional `composedTraits`.
- **FR-013**: Blueprints bundle Resources + Traits into "golden path" patterns.

#### Component

- **FR-014**: `#Component` merges specs from `#resources`, `#traits`, `#blueprints`, and `#policies` into a unified `spec` field.
- **FR-015**: Component `spec` MUST use `close()` with spread operator for type safety with transformer validation.

#### Scope

- **FR-016**: `#Scope` applies scope-level Policies to groups of components.
- **FR-017**: Scope MUST have `appliesTo` selectors (`componentLabels`, `components`, or `all`).
- **FR-018**: Scope `#policies` MUST only accept Policies with `target: "scope"`.

#### Module

- **FR-019**: `#Module` is the portable application blueprint containing `#components`, `#values`, optional `#scopes`, and optional `#policies`.
- **FR-020**: Module `#policies` are for runtime enforcement that CUE cannot validate at evaluation time.
- **FR-021**: Module MUST be accompanied by a `values.cue` file with default values.

#### ModuleCompiled

- **FR-022**: `#ModuleCompiled` is the compiled/optimized form with expanded Blueprints.
- **FR-023**: ModuleCompiled is ready for value binding and deployment.

#### ModuleRelease

- **FR-024**: `#ModuleRelease` binds a Module to concrete values and a target namespace.
- **FR-025**: ModuleRelease MUST unify values with the Module's `#values` schema.

### Naming and Identification

- **FR-026**: `#FQNType` format: `<repo-path>@v<major>#<Name>` (e.g., `opm.dev/resources/workload@v0#Container`).
- **FR-027**: `#VersionType` validates semantic versioning (major.minor.patch with optional prerelease/build).
- **FR-028**: `#NameType` is a string between 1-254 characters.
- **FR-029**: All definitions MUST have a computed `fqn` field: `"\(metadata.apiVersion)#\(metadata.name)"`.

### Values System

- **FR-030**: `#values` in Module MUST be an OpenAPIv3-compatible schema (no CUE templating).
- **FR-031**: `values.cue` file MUST contain concrete defaults satisfying the `#values` schema.
- **FR-032**: Value override hierarchy: developer defaults → platform team overrides → end-user overrides.
- **FR-033**: Platform team overrides become immutable for end-users.

### Provider and Transformation

#### Transformer Structure

- **FR-034**: `#Provider` contains a transformer registry mapping to platform resources.
- **FR-035**: `#Transformer` declares `requiredLabels`, required/optional resources, traits, policies, and a `#transform` function.
- **FR-036**: Transformer `#transform` MUST output a list of resources (even for single-resource output).
- **FR-037**: Provider MUST compute `#declaredResources`, `#declaredTraits`, `#declaredPolicies` from transformers.
- **FR-038**: `#Renderer` converts transformed resources to manifest formats (yaml/json/toml/hcl).

#### Label-Based Matching (FR-045 to FR-051)

See [Transformer Matching Subsystem](./subsystems/transformer-matching.md) for detailed requirements covering:

- Label-based matching algorithm (FR-045 to FR-047)
- Conflict detection for identical vs complementary transformers (FR-048, FR-049)
- Transform execution and output concatenation (FR-050, FR-051)

### Bundles and Templates

- **FR-039**: `#Bundle` groups related Modules.
- **FR-040**: `#BundleCompiled` is the compiled form of a Bundle.
- **FR-041**: `#BundleRelease` deploys a Bundle with concrete values.
- **FR-042**: `#Template` defines module initialization templates.

### Validation and Type Safety

- **FR-043**: All definition `#spec` fields MUST be OpenAPIv3 compatible.
- **FR-044**: Definition structs MUST use `close({})` to prevent unspecified fields.

## Key Entities

### Definition Types (Building Blocks)

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Resource` | Deployable unit | `#spec`, `#defaults` |
| `#Trait` | Behavior modifier | `appliesTo`, `#spec`, `#defaults` |
| `#Policy` | Governance constraint | `target`, `enforcement`, `#spec`, `#defaults` |
| `#Blueprint` | Reusable pattern | `composedResources`, `composedTraits`, `#spec` |

### Composition Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Component` | Logical app part | `#resources`, `#traits`, `#blueprints`, `#policies`, `spec` |
| `#Scope` | Policy applicator | `#policies`, `appliesTo`, `spec` |

### Module Types

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| `#Module` | Portable blueprint | `#components`, `#scopes`, `#policies`, `#values` |
| `#ModuleCompiled` | Compiled form | Expanded blueprints, resolved defaults |
| `#ModuleRelease` | Deployment instance | `module`, `values`, `namespace` |

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

## Success Criteria

- **SC-001**: All core definition types validate with `cue vet` when given valid input.
- **SC-002**: Invalid definitions are rejected with clear error messages.
- **SC-003**: Policy target mismatches are caught by CUE unification.
- **SC-004**: Component `spec` correctly merges fields from all attached definitions.
- **SC-005**: Modules without `values.cue` fail validation.
- **SC-006**: Platform-locked values cannot be overridden by end-users.
- **SC-007**: Provider correctly computes declared resources/traits/policies from transformers.
- **SC-008**: Transformer matching correctly uses `requiredLabels` - only transformers whose labels match component labels are candidates.
- **SC-009**: Multiple exact transformer matches (identical requirements) produce an error.
- **SC-010**: Complementary transformers (different requirements) both match and produce concatenated output.

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
