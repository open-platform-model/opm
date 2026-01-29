# Feature Specification: Resource Definition Specification

**Feature Branch**: `004-definition-resource`
**Created**: 2026-01-25
**Status**: Draft
**Input**: User description: "Create definition-resource-spec based on component-resource.md and opm_spec_ideas.md"

> **Feature Availability**: This definition is **enabled** in CLI v1.

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Authoring a Resource Definition (Priority: P1)

A **Module Author** needs to define a new Resource type (e.g., `PostgresDB`) so that it can be used within Components.

**Why this priority**: Resources are the fundamental atoms of OPM. Without the ability to define them, no other composition is possible.

**Independent Test**: Can be tested by writing a CUE file matching the `#Resource` schema and validating it with `cue vet`.

**Acceptance Scenarios**:

1. **Given** a new CUE file importing `opmodel.dev/core`, **When** the author defines a `#Resource` struct with valid metadata and `#spec`, **Then** it should validate successfully.
2. **Given** a Resource named "Container", **When** the `#spec` defines a field named "container", **Then** validation succeeds.
3. **Given** a Resource named "Container", **When** the `#spec` defines a field named "wrongName", **Then** validation fails (key mismatch).

---

### User Story 2 - Publishing a Resource (Priority: P2)

A **Platform Operator** needs to publish a validated Resource definition to an OCI registry so that it can be discovered and used by others.

**Why this priority**: Distribution is key for reuse across teams and modules.

**Independent Test**: Can be tested using the defined CLI command against a local or mock registry.

**Acceptance Scenarios**:

1. **Given** a valid `resource.cue` file, **When** running `cue mod publish <version>`, **Then** the module is pushed to the registry path defined in `apiVersion`.
2. **Given** an invalid Resource definition, **When** running `opm def resource vet`, **Then** the CLI reports specific validation errors.

---

### User Story 3 - Using a Resource in a Component (Priority: P1)

A **Module Author** needs to use a published Resource in a Component to define what infrastructure should exist.

**Why this priority**: This is the primary consumption point for Resources.

**Independent Test**: Can be tested by creating a Component that imports the Resource.

**Acceptance Scenarios**:

1. **Given** a Component definition, **When** a Resource is added to `#resources`, **Then** the Component inherits the Resource's labels.
2. **Given** a Component, **When** it has no Resources defined, **Then** validation fails (Component MUST have at least one Resource).

## Edge Cases

- **Circular Dependencies**: Resources should not depend on other Resources (they are atomic).
- **Naming Conflicts**: What happens if two resources have the same FQN? (Registry should reject duplicates).

## Requirements *(mandatory)*

### Functional Requirements

#### Schema & Structure

- **FR-001**: The system MUST provide a `#Resource` CUE definition that is a closed struct.
- **FR-002**: The `#Resource` schema MUST require `metadata` containing `apiVersion`, `name`, and computed `fqn`.
- **FR-003**: The `metadata.fqn` MUST be computed as `"{apiVersion}#{name}"`.
- **FR-004**: The `#spec` field key MUST automatically match the `strings.ToCamel(metadata.name)` version of the Resource name (e.g., `Container` -> `container`).
- **FR-005**: The `#spec` definition MUST be OpenAPIv3 compatible (concrete data schema) to ensure exportability.
- **FR-006**: The `#Resource` schema MUST support an optional `#defaults` field to provide default values for `#spec`.

#### Behavior & Inheritance

- **FR-007**: Components consuming a Resource MUST inherit all `metadata.labels` defined in that Resource.
- **FR-008**: A Component MUST be validated to contain at least one Resource in its `#resources` map (Existence Principle).
- **FR-009**: The system MUST support label-based platform compatibility declarations (e.g., `core.opmodel.dev/platform: kubernetes`).

#### CLI Interface

- **FR-010**: The CLI MUST support initializing a new Resource via `opm def resource init`.
- **FR-011**: The CLI MUST support validating a Resource via `opm def resource vet`.
- **FR-012**: Resource publishing MUST use the standard CUE module workflow via `cue mod publish <version>`.

### Key Entities

- **#Resource**: The definition schema.
- **#spec**: The schema defining the configuration surface of the resource.
- **Registry**: OCI-compliant storage for versioned Resource definitions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A valid `#Resource` definition can be rendered to a pure OpenAPI schema without errors.
- **SC-002**: The `opm def resource vet` command returns 0 exit code for valid resources and non-zero for invalid ones.
- **SC-003**: Users can successfully define a Resource with at least 5 nested fields and validate it.
- **SC-004**: Label inheritance is verifiable: 100% of labels defined in a Resource appear in the consuming Component's metadata.

## Assumptions

- The Core CUE module (`opmodel.dev/core`) is available and versioned.
- OCI registry authentication is handled by the underlying CLI config.
