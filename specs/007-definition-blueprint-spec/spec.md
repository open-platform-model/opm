# Feature Specification: Definition Blueprint Specification

**Feature Branch**: `007-definition-blueprint-spec`  
**Created**: 2026-01-25  
**Status**: Draft  
**Input**: User description: "Lets make a plan to create a new specification called \"definition-blueprint-spec\" @opm_spec_ideas.md. Copy from component-blueprint.md @opm/specs/001-core-definitions-spec/subspecs/ but leave a reference, just as we did in module-status.md."

## Overview

This specification defines how Blueprint definitions are authored, validated, and consumed as reusable compositions of Resources and Traits. It supersedes the earlier Blueprint subspec located at `opm/specs/001-core-definitions-spec/subspecs/component-blueprint.md`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Author a reusable blueprint (Priority: P1)

As a module author, I want to define a Blueprint that bundles Resources and Traits so teams can reuse a proven architectural pattern.

**Why this priority**: Blueprint authoring is the foundation for reuse and must work before any consumption is possible.

**Independent Test**: Create a Blueprint definition with required fields and confirm it validates as a standalone spec artifact.

**Acceptance Scenarios**:

1. **Given** a draft Blueprint definition with metadata and at least one composed Resource, **When** it is validated, **Then** the definition is accepted as a Blueprint.
2. **Given** a Blueprint definition with a declared name, **When** its spec interface is reviewed, **Then** the top-level spec key matches the camelCase form of the name.

---

### User Story 2 - Consume a blueprint in a component (Priority: P2)

As a component author, I want to reference a Blueprint and configure it through its exposed interface without needing to understand every underlying Resource or Trait.

**Why this priority**: Blueprint adoption is the main value to end users and proves the spec enables composition.

**Independent Test**: Reference a Blueprint from a Component and verify the component reflects the composed Resources and Traits.

**Acceptance Scenarios**:

1. **Given** a Component that references a Blueprint, **When** the Component is evaluated, **Then** all composed Resources and Traits are included as if directly attached.

---

### User Story 3 - Review blueprint consistency (Priority: P3)

As a platform operator, I want to review Blueprint definitions for consistent metadata and compatibility so I can curate a trusted catalog.

**Why this priority**: Catalog quality is important but depends on Blueprint authoring and consumption already working.

**Independent Test**: Review a Blueprint's metadata and composed definitions and confirm it meets the catalog policy rules.

**Acceptance Scenarios**:

1. **Given** a Blueprint with metadata and composed definitions, **When** it is reviewed, **Then** its metadata and composed elements satisfy the validation rules in this specification.

---

### User Story 4 - Publishing a Blueprint (Priority: P2)

As a Platform Operator, I want to publish validated Blueprint definitions to an OCI registry so they can be reused across teams.

**Why this priority**: Blueprints only deliver reuse once they can be distributed from a catalog.

**Independent Test**: Publish a blueprint module to a local registry using `cue mod publish` and verify the artifact exists.

**Acceptance Scenarios**:

1. **Given** a valid Blueprint definition module, **When** running `cue mod publish <version>`, **Then** the module is pushed to the registry.

---

### Edge Cases

- Blueprint definition omits composed Resources.
- Blueprint spec interface key does not match the camelCase name.
- Blueprint references Resources or Traits that cannot be resolved from the catalog.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Blueprint definitions MUST include `apiVersion`, `kind`, `metadata`, `composedResources`, and `#spec` fields.
- **FR-002**: `kind` MUST be `Blueprint`, and `metadata` MUST include `apiVersion`, `name`, and a fully qualified name derived from `apiVersion` and `name`.
- **FR-003**: `composedResources` MUST be a non-empty list of Resource definitions and each entry MUST be a full reference.
- **FR-004**: `composedTraits` MAY be provided; when present, each entry MUST be a Trait definition reference.
- **FR-005**: `#spec` MUST define the configuration interface for the Blueprint and MUST expose a top-level field whose key matches the camelCase form of `metadata.name`.
- **FR-006**: Components that use a Blueprint MUST inherit the Blueprint's composed Resources and Traits as if they were attached directly.
- **FR-007**: Components that use a Blueprint MUST inherit labels from the Blueprint and from all composed Resources and Traits.
- **FR-008**: Blueprint fully qualified names MUST follow the registry format for Blueprint definitions.

### Key Entities *(include if feature involves data)*

- **Blueprint Definition**: A reusable composition that bundles Resources and Traits and exposes a configuration interface.
- **Resource Definition**: The deployable unit referenced in a Blueprint's composition list.
- **Trait Definition**: The behavior modifier referenced in a Blueprint's optional composition list.
- **Component**: The consumer that references a Blueprint and receives its composed elements.
- **Blueprint Interface**: The exposed configuration surface defined in `#spec`.

## Assumptions

- Blueprints do not compose other Blueprints unless explicitly added in a future revision.
- Blueprints do not include Policies in their composition in this revision.
- Blueprint authors decide which configuration fields are exposed through the Blueprint interface.

## Dependencies

- None.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Independent reviewers reach identical pass/fail validation results for 10 sample Blueprint definitions based on this specification.
- **SC-002**: 90% of module authors can create a valid Blueprint definition within 60 minutes using only this specification.
- **SC-003**: 95% of component authors can correctly identify which Resources and Traits are included by a Blueprint from its definition alone.
- **SC-004**: At least three representative Blueprint patterns can be expressed without exceptions or amendments to the specification.
