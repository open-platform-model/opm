# Feature Specification: Policy Definition

**Feature Branch**: `006-definition-policy-spec`
**Created**: 2026-01-25
**Status**: Draft
**Input**: User description: "Lets make a plan to create a new specification called \"definition-policy-spec\" @opm_spec_ideas.md. Copy from policy.md @opm/specs/001-core-definitions-spec/subspecs/ but leave a reference, just as we did in module-status.md."

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Define Governance Constraints (Priority: P1)

As a Platform Operator, I want to define policies that enforce security and operational standards (like mTLS or quotas) so that I can ensure all modules in the catalog adhere to compliance requirements.

**Why this priority**: Policies are the core mechanism for governance. Without the ability to define them, the system lacks control.

**Independent Test**: Can be tested by creating a valid `#Policy` definition and verifying it passes `opm def policy vet`.

**Acceptance Scenarios**:

1. **Given** a valid Policy definition with `target: "scope"`, **When** validated, **Then** it passes validation.
2. **Given** a Policy with missing `enforcement` configuration, **When** validated, **Then** it fails with a specific error.
3. **Given** a Policy with an invalid `target`, **When** validated, **Then** it fails validation.

---

### User Story 2 - Enforce Policy at Deployment (Priority: P1)

As an Infrastructure Operator, I want policies to block non-compliant deployments so that bad configurations never reach production.

**Why this priority**: Enforcement is the "teeth" of the policy system.

**Independent Test**: Can be tested by simulating a deployment with a violating component and ensuring the operation is blocked.

**Acceptance Scenarios**:

1. **Given** a Policy with `enforcement.mode: "deployment"` and `onViolation: "block"`, **When** a violating component is deployed, **Then** the deployment is rejected.
2. **Given** a Policy with `onViolation: "warn"`, **When** a violation occurs, **Then** a warning is logged but deployment proceeds.

---

### User Story 3 - Apply Policy to Scope (Priority: P2)

As a Module Author, I want to apply policies to specific scopes of components so that I can easily manage cross-cutting concerns like networking or observability.

**Why this priority**: Allows granular application of policies rather than global-only.

**Independent Test**: Can be tested by defining a `#Scope` with `#policies` and checking if the target components receive the policy configuration.

**Acceptance Scenarios**:

1. **Given** a `#Scope` applying a NetworkPolicy, **When** processed, **Then** the target components inherit the policy's spec.
2. **Given** a Policy applied to the wrong target level, **When** processed, **Then** a unification error occurs.

---

### User Story 4 - Publishing a Policy (Priority: P2)

As a Platform Operator, I want to publish validated Policy definitions to an OCI registry so they can be shared across teams.

**Why this priority**: Policies are only reusable across catalogs when they can be distributed consistently.

**Independent Test**: Publish a policy module to a local registry using `cue mod publish` and verify the artifact exists.

**Acceptance Scenarios**:

1. **Given** a valid Policy definition module, **When** running `cue mod publish <version>`, **Then** the module is pushed to the registry.

---

### Edge Cases

| Case | Behavior |
|------|----------|
| Policy with wrong target | CUE unification error at application point |
| Missing `enforcement` field | CUE validation error (required) |
| Missing `enforcement.mode` | CUE validation error (required) |
| Missing `enforcement.onViolation` | CUE validation error (required) |
| `enforcement.platform` not specified | Valid (platform uses defaults) |
| Multiple policies same level | All merged into spec |
| Conflicting policy specs | CUE unification error |
| Policy without `#spec` | CUE validation error (required) |

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support `#Policy` definitions with `apiVersion`, `kind: "Policy"`, and `metadata`.
- **FR-002**: Policies MUST specify a `target` field, currently restricted to `"scope"`.
- **FR-003**: Policies MUST include an `enforcement` block configuring `mode` ("deployment", "runtime", "both") and `onViolation` ("block", "warn", "audit").
- **FR-004**: Policies MAY include a `platform` field for specific implementation configs (Kyverno, OPA).
- **FR-005**: The system MUST validate that policies are applied only to their declared target (e.g., `#Scope.#policies`).
- **FR-006**: When applied to a scope, the policy's `#spec` MUST be merged into the scope's spec for distribution to components.
- **FR-007**: Conflicting policy specs within the same scope MUST result in a CUE unification error.

### Key Entities

- **Policy**: A definition defining a constraint and its enforcement rules.
- **Scope**: The target container where policies are applied to a group of components.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of invalid policy definitions (missing fields, wrong types) are caught by validation tools.
- **SC-002**: Policy application respects the `target` constraint; applying a scope policy to a component directly fails 100% of the time.
- **SC-003**: Enforcement modes (`block`, `warn`, `audit`) trigger the correct system response in 100% of test cases.

---

## Detailed Specification

*(Ported from Module Policy Subsystem)*

### Overview

This document defines the OPM policy system at the scope application level. Policies are governance constraints with enforcement consequences - they express what MUST be true, not suggestions.

### Schema

```cue
#Policy: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "Policy"

    metadata: {
        apiVersion!:  string  // e.g., "opm.dev/policies/security@v0"
        name!:        string  // e.g., "SecurityContext"
        fqn:          string  // Computed: "{apiVersion}#{name}"
        description?: string
        
        // Where this policy can be applied
        target!: "scope"
        
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Enforcement configuration
    enforcement!: {
        // When enforcement happens
        mode!: "deployment" | "runtime" | "both"
        
        // What happens on violation
        onViolation!: "block" | "warn" | "audit"
        
        // Platform-specific enforcement (Kyverno, OPA, etc.)
        platform?: _
    }

    // Policy specification schema
    #spec!: _
})
```

### Enforcement Configuration

| Mode | When Checked | Use Case |
|------|--------------|----------|
| `deployment` | At deploy time | Schema validation, limits |
| `runtime` | Continuously | Rate limiting, quotas |
| `both` | Both | Security policies |

| Response | Behavior | Use Case |
|----------|----------|----------|
| `block` | Reject operation | Security violations |
| `warn` | Log warning | Deprecation notices |
| `audit` | Record only | Compliance tracking |

### Target Validation

CUE enforces that policies are applied at the correct level. Attempting to apply a policy with `target: "scope"` to anything other than `#Scope.#policies` results in a unification error.

### Examples

**Network Policy:**

```cue
#NetworkPolicy: #Policy & {
    metadata: {
        apiVersion: "opm.dev/policies/network@v0"
        name:       "NetworkPolicy"
        target:     "scope"
    }
    
    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }
    
    #spec: networkPolicy: {
        ingress?: [...{from: [...string], ports: [...int]}]
        egress?:  [...{to: [...string], ports: [...int]}]
    }
}
```
