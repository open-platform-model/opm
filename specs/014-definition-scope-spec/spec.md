# Feature Specification: Scope Definition Specification

**Feature Branch**: `014-definition-scope-spec`  
**Created**: 2026-01-25  
**Status**: Draft  
**Input**: User description: "Create a new definition-spec for #Scope and reference it in the 001 scope subspec."

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## Overview

This specification defines the #Scope definition used to apply Policies across groups of Components in a Module. It supersedes the scope subspec in `opm/specs/001-core-definitions-spec/subspecs/scope.md`.

Scopes are cross-cutting policy applicators. They centralize governance without duplicating policies across each component.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Apply governance across components (Priority: P1)

A Platform Operator wants to define a Scope that applies one or more policies to a group of components without editing each component.

**Why this priority**: This is the primary reason scopes exist and unlocks scalable governance.

**Independent Test**: Create a module with a scope that targets multiple components and verify that the scope policies are applied to all targeted components.

**Acceptance Scenarios**:

1. **Given** a Scope with two policies and a list of target components, **When** the module is evaluated, **Then** both policies apply to each targeted component.
2. **Given** a Scope with no matching components, **When** the module is evaluated, **Then** the scope is valid but has no effect.

---

### User Story 2 - Target components with selectors (Priority: P2)

A Module Author wants to target components by label or direct reference so that scopes are applied precisely.

**Why this priority**: Selectors make scopes practical for real modules without hardcoding every component name.

**Independent Test**: Define a scope with label selectors and ensure it selects the intended components.

**Acceptance Scenarios**:

1. **Given** components labeled with `tier: backend`, **When** a scope uses label selectors for `tier: backend`, **Then** only backend components are targeted.
2. **Given** a scope with both label selectors and explicit component references, **When** evaluated, **Then** components matching either selector are targeted.

---

### User Story 3 - Validate policy targeting (Priority: P2)

A Platform Operator wants invalid policies rejected when they are not scoped for scope-level enforcement.

**Why this priority**: Ensures governance rules are attached at the correct level and avoids misconfiguration.

**Independent Test**: Add a policy with a non-scope target to a scope and confirm validation fails.

**Acceptance Scenarios**:

1. **Given** a policy whose target is not `scope`, **When** it is placed in `#Scope.#policies`, **Then** validation fails with a target mismatch.

---

### Edge Cases

- Scope defines no selectors but includes policies.
- Scope selectors reference non-existent components.
- Policies within the same scope define conflicting spec fields.
- Multiple scopes apply the same policy to the same component.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a `#Scope` definition as a closed struct.
- **FR-002**: `#Scope` MUST require `metadata.name` and allow optional labels and annotations.
- **FR-003**: `#Scope` MUST define a `#policies` map that only accepts policies with `target: "scope"`.
- **FR-004**: `#Scope` MUST define `appliesTo` for selecting components.
- **FR-005**: `appliesTo.components` MUST support direct component references and module-wide lists.
- **FR-006**: `appliesTo.componentLabels` MUST support label-based selection.
- **FR-007**: When both selector types are provided, they MUST be combined with OR logic.
- **FR-008**: `#Scope.spec` MUST be derived from flattening all attached policy `#spec` fields.
- **FR-009**: Conflicting policy specs in the same scope MUST fail validation.
- **FR-010**: Components targeted by a scope MUST receive the scope's policies as part of module evaluation.

### Key Entities *(include if feature involves data)*

- **Scope**: Cross-cutting policy applicator that targets a group of components.
- **Policy**: Governance definition applied by a scope.
- **AppliesTo Selector**: Selector block that determines component targets.
- **Component**: Module element that receives policies via scopes.

## Assumptions

- Modules expose a component list and component labels for scope selection.
- Policies expose a target field and a spec block that can be merged.

## Dependencies

- Policy definition specification
- Component definition specification

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Independent reviewers reach identical pass/fail outcomes for 10 sample scope definitions.
- **SC-002**: 100% of policies with non-scope targets are rejected when attached to a scope.
- **SC-003**: 90% of module authors can correctly target a subset of components using selectors in under 15 minutes using only this specification.
- **SC-004**: A validation suite detects all conflicting policy specs within a scope.
