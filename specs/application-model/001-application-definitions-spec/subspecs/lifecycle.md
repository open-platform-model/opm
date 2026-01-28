# Lifecycle Definition

**Parent Spec**: [OPM Core CUE Specification](../spec.md)
**Status**: Draft
**Last Updated**: 2026-01-26

> **Feature Availability**: This definition is specified but currently **deferred** in CLI v1 to reduce initial complexity. It will be enabled in a future release.

## Overview

This document defines the `#Lifecycle` system for the Open Platform Model (OPM). Lifecycle describes the operational actions that execute during key transition points: **Install**, **Upgrade**, and **Delete**.

The `#Lifecycle` definition is **unified**—the same schema is used by both `#Component` and `#Module`. While the structure is identical, the *context* and *execution timing* differ depending on where it is attached.

### Core Principles

1. **Pre-Built Blocks Only**: All lifecycle steps are reusable blocks from a catalog (referenced by FQN). Custom inline scripts are not allowed. This ensures safety, auditability, and consistency.
2. **Sequential Phases**: Operations occur in distinct phases (`before` and `after` resources are applied).
3. **Orchestrated Order**: Component lifecycles typically run *before* Module lifecycles during deployment, ensuring building blocks are ready before higher-level orchestration occurs.

## Schema

The `#Lifecycle` definition serves as the schema for both `#Component.lifecycle` and `#Module.lifecycle`.

```cue
// A set of lifecycle hooks for a definition
#Lifecycle: {
    // Steps before/after initial deployment
    install?: #LifecyclePhase

    // Steps before/after version changes or config updates
    upgrade?: #LifecyclePhase

    // Steps before/after removal
    delete?: #LifecyclePhase
}

// A single transition phase containing ordered steps
#LifecyclePhase: {
    // Executed BEFORE resources are applied/modified
    before?: [...#LifecycleStep]

    // Executed AFTER resources are ready/stabilized
    after?:  [...#LifecycleStep]
}

// A single operational step
#LifecycleStep: {
    // Fully Qualified Name of the lifecycle block from catalog
    fqn!: string

    // Human-readable description
    description?: string

    // Conditional execution (CUE expression evaluating to bool)
    condition?: string

    // Maximum execution time (e.g., "5m", "30s")
    timeout?: string

    // Behavior on failure
    // abort: Stop execution, mark as failed (Default)
    // continue: Log error, proceed to next step
    // rollback: Stop execution, attempt to undo previous steps
    onFailure?: "abort" | "continue" | "rollback"

    // Step-specific configuration (input for the block)
    config?: _
}
```

## Context & Usage

While the schema is shared, the runtime context differs.

### 1. Component Lifecycle

Attached to a `#Component`. Used for actions scoped to that specific component, such as database migrations or cache warming.

* **Context Available**: The component's own `values`, `resources`, and `outputs`.
* **Execution**:
  * **Install/Upgrade**: Runs *before* the Module lifecycle.
  * **Delete**: Runs *after* the Module lifecycle (reverse dependency order).

### 2. Module Lifecycle

Attached to a `#Module`. Used for cross-component coordination, integration testing, or external system registration (DNS, Notifications).

* **Context Available**: The entire module's `values`, plus `outputs` from *all* contained components.
* **Execution**:
  * **Install/Upgrade**: Runs *after* all components are successfully deployed and ready.
  * **Delete**: Runs *before* any components are deleted.

## Execution Model

The platform orchestrator executes lifecycles in the following order:

### Install / Upgrade Flow

1. **Component `before` Hooks**: All components run their `install.before` or `upgrade.before` steps.
2. **Resource Application**: Platform applies resources for all components.
3. **Wait for Ready**: Platform waits for resources to become healthy.
4. **Component `after` Hooks**: All components run their `install.after` or `upgrade.after` steps.
5. **Module `before` Hooks**: Module runs its `install.before` or `upgrade.before` steps.
    * *Note: Module 'before' hooks effectively run after components are ready, but before the module is considered "provisioned".*
6. **Module `after` Hooks**: Module runs its `install.after` or `upgrade.after` steps.

### Delete Flow (Reverse Order)

1. **Module `before` Hooks**: Run cleanup/notification logic while components still exist.
2. **Module `after` Hooks**: (Rarely used, but available).
3. **Component `before` Hooks**: Run per-component cleanup (e.g., data export).
4. **Resource Deletion**: Platform removes resources.
5. **Component `after` Hooks**: Final cleanup.

## Examples

### Component Lifecycle (Database Migration)

```cue
database: #Component & {
    #resources: { ... }

    #lifecycle: {
        upgrade: {
            before: [
                {
                    fqn: "opm.dev/lifecycle/data@v0#Backup"
                    description: "Backup before schema change"
                    config: { target: "s3://backups" }
                },
                {
                    fqn: "opm.dev/lifecycle/data@v0#Migrate"
                    description: "Run schema migrations"
                    onFailure: "rollback"
                }
            ]
        }
    }
}
```

### Module Lifecycle (Integration Test)

```cue
myModule: #Module & {
    #components: {
        api: { ... }
        db: { ... }
    }

    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opm.dev/lifecycle/test@v0#IntegrationTest"
                    description: "Verify API can talk to DB"
                    config: {
                        endpoints: ["http://api", "postgres://db"]
                    }
                },
                {
                    fqn: "opm.dev/lifecycle/notify@v0#Slack"
                    description: "Notify team of success"
                    onFailure: "continue"
                }
            ]
        }
    }
}
```

## User Scenarios & Testing

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE.
-->

### User Story 1 - Component Data Migration (Priority: P1)

As a **Module Author**, I want to execute a schema migration script before my application code updates, so that the database structure is compatible with the new version.

**Why this priority**: Essential for stateful application upgrades. Without this, updating databases safely is impossible.

**Independent Test**: Define a mock component with a database schema version 1. Define an upgrade lifecycle hook that migrates it to version 2. Perform an upgrade.

**Acceptance Scenarios**:

1. **Given** a Component with an `upgrade.before` lifecycle step defined, **When** the component version is updated, **Then** the migration step executes and completes successfully *before* the platform updates the component's resources.
2. **Given** a migration step that fails, **When** the upgrade is attempted, **Then** the resource update is blocked and the system halts (or rolls back per policy).

---

### User Story 2 - Automatic Rollback on Failure (Priority: P1)

As a **Platform Operator**, I want the deployment to automatically revert if a critical lifecycle step fails, so that production never stays in a broken state.

**Why this priority**: Critical for system reliability and "safe by default" operations.

**Independent Test**: Configure a lifecycle step to intentionally fail (exit code 1) with `onFailure: "rollback"`.

**Acceptance Scenarios**:

1. **Given** a lifecycle step with `onFailure: "rollback"`, **When** that step fails (returns non-zero exit code), **Then** the platform stops forward progress.
2. **And** reverts any changes made in previous steps in reverse order (where applicable) and restores the previous stable state.

---

### User Story 3 - Module Integration Testing (Priority: P2)

As a **Module Author**, I want to run a test suite that verifies cross-component communication after deployment, so that I can guarantee the stack is functional before marking it successful.

**Why this priority**: Ensures high-level quality assurance and prevents "green" deployments that are actually broken.

**Independent Test**: Create a module with two components (API and DB). Add an `install.after` step that curls the API endpoint.

**Acceptance Scenarios**:

1. **Given** a Module with an `install.after` step configured to run tests, **When** the module is installed, **Then** the platform waits for all components to be "Ready".
2. **And** only then executes the test step.

---

### User Story 4 - External Registration (Priority: P2)

As a **Platform Operator**, I want to register DNS and notify Slack when a module is fully ready, so that the service is discoverable without manual toil.

**Why this priority**: Automates post-deployment "glue" tasks, reducing operator burden.

**Independent Test**: Configure an `install.after` step that prints a "notification" to stdout (mocking the external call).

**Acceptance Scenarios**:

1. **Given** a Module lifecycle step for DNS registration in `install.after`, **When** the module deployment finishes successfully, **Then** the registration block runs using the outputs (IP addresses) from the deployed components.
2. **Given** a failure in the registration step with `onFailure: "continue"`, **When** it fails, **Then** the deployment is still marked as successful (with a warning).

## Functional Requirements

* **FR-11-001**: System MUST support `#Lifecycle` definition on both `#Component` and `#Module`.
* **FR-11-002**: Lifecycle steps MUST reference pre-built blocks from catalog via `fqn`.
* **FR-11-003**: Custom/inline lifecycle step implementation is NOT allowed.
* **FR-11-004**: System MUST execute Component lifecycles before Module lifecycles during Install/Upgrade.
* **FR-11-005**: System MUST execute Module lifecycles before Component lifecycles during Delete.
* **FR-11-006**: Step `condition` field MUST be evaluated against the relevant context (Component or Module).
* **FR-11-007**: Step failures MUST trigger the configured `onFailure` behavior (`abort`, `continue`, `rollback`).
