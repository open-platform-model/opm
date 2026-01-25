# Feature Specification: Trait Definition Specification

**Feature Branch**: `005-definition-trait`
**Created**: 2026-01-25
**Status**: Draft
**Input**: User description: "Create definition-trait-spec based on component-trait.md and opm_spec_ideas.md"

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Authoring a Trait Definition (Priority: P1)

A **Module Author** needs to define a new Trait (e.g., `Replicas` or `Ingress`) that describes a specific behavior or configuration capability that can be added to compatible Resources.

**Why this priority**: Traits are the mechanism for defining "how" a resource operates, separating operational concerns from structural ones.

**Independent Test**: Can be tested by writing a CUE file matching the `#Trait` schema and validating it with `cue vet`.

**Acceptance Scenarios**:

1. **Given** a new CUE file importing `opm.dev/core`, **When** the author defines a `#Trait` struct with valid metadata, `appliesTo` list, and `#spec`, **Then** it should validate successfully.
2. **Given** a Trait named "Replicas", **When** the `#spec` defines a field named "replicas", **Then** validation succeeds.
3. **Given** a Trait named "Replicas", **When** the `#spec` defines a field named "wrongName", **Then** validation fails (key mismatch).
4. **Given** a Trait with an empty `appliesTo` list, **When** validating, **Then** validation fails (Traits MUST declare applicability).

---

### User Story 2 - Applying a Trait to a Component (Priority: P1)

A **Module Author** needs to apply a Trait to a Component to enable specific behaviors (e.g., scaling).

**Why this priority**: This is how Traits are consumed and where the primary validation logic resides.

**Independent Test**: Can be tested by creating a Component with a Resource and a Trait.

**Acceptance Scenarios**:

1. **Given** a Component with a Resource (e.g., Container) and a Trait (e.g., Replicas), **When** the Trait's `appliesTo` includes the Resource, **Then** validation succeeds.
2. **Given** a Component with a Resource (e.g., Volume) and a Trait (e.g., Replicas for Container only), **When** validation runs, **Then** it MUST fail with an incompatibility error.
3. **Given** a Trait with defaults (e.g., replicas=1), **When** applied to a Component that doesn't specify that value, **Then** the Component's spec evaluates to the default value.

---

### User Story 3 - Publishing a Trait (Priority: P2)

A **Platform Operator** needs to publish a validated Trait definition to the registry.

**Why this priority**: Enables sharing of operational behaviors across the platform.

**Independent Test**: Can be tested via CLI commands against a registry.

**Acceptance Scenarios**:

1. **Given** a valid Trait definition, **When** running `opm def trait publish`, **Then** it is successfully pushed to the registry.

## Edge Cases

- **Circular Dependencies**: Traits should not depend on other Traits unless explicitly designed (assumed 'No' for MVP).
- **Multiple Traits**: Multiple traits can apply to the same component; CUE handles unification conflicts.
- **Empty Applicability**: A Trait with no `appliesTo` targets is invalid.

## Requirements *(mandatory)*

### Functional Requirements

#### Schema & Structure

- **FR-001**: The system MUST provide a `#Trait` CUE definition that is a closed struct.
- **FR-002**: The `#Trait` schema MUST require `metadata` containing `apiVersion`, `name`, and computed `fqn`.
- **FR-003**: The `#Trait` schema MUST require an `appliesTo` field, which is a list of `#Resource` definitions (whitelist).
- **FR-004**: The `#spec` field key MUST automatically match the `strings.ToCamel(metadata.name)` version of the Trait name.
- **FR-005**: The `#spec` definition MUST be OpenAPIv3 compatible.
- **FR-006**: The `#Trait` schema MUST support an optional `#defaults` field to provide default values for `#spec`.

#### Behavior & Composition

- **FR-007**: When applied to a Component, the system MUST validate that at least one of the Component's Resources is present in the Trait's `appliesTo` list.
- **FR-008**: Components consuming a Trait MUST inherit all `metadata.labels` defined in that Trait.
- **FR-009**: The `#spec` of the Trait MUST be unified into the Component's `spec` field.
- **FR-010**: Conflicting values in `#spec` between the Component and Trait (or multiple Traits) MUST result in a CUE unification error.

#### CLI Interface

- **FR-011**: The CLI MUST support initializing a new Trait via `opm def trait init`.
- **FR-012**: The CLI MUST support validating a Trait via `opm def trait vet`.
- **FR-013**: The CLI MUST support publishing a Trait via `opm def trait publish`.

### Key Entities

- **#Trait**: The definition schema for behaviors.
- **#Resource**: The definition schema that Traits apply to.
- **Component**: The composition unit where Traits and Resources are combined.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A valid `#Trait` definition validates against the core schema with 0 errors.
- **SC-002**: Incompatibility detection (Trait applied to wrong Resource) occurs during CUE evaluation time (not runtime).
- **SC-003**: `opm def trait vet` correctly identifies 100% of schema violations in a test suite of invalid traits.
- **SC-004**: Users can successfully publish a Trait to a registry within standard network latency times (< 2s for typical payload).

## Assumptions

- `appliesTo` uses full definition references (CUE paths) for matching.
- Traits do not currently support dependencies on other Traits (as per "Open Questions" in ideas file, we assume 'No' for MVP unless specified).
- Trait ordering is not guaranteed; conflicts are resolved by standard CUE unification rules (commutative).
