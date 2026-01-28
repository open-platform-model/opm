# Feature Specification: Definition Status System

**Feature Branch**: `008-definition-status-spec`  
**Created**: 2026-01-24  
**Status**: Draft  
**Input**: User description: "Create unified Status and StatusProbe definitions for Components, Modules, and Bundles"

> **Feature Availability**: This definition is specified but currently **deferred** in CLI v1 to reduce initial complexity. It will be enabled in a future release.

> **IMPORTANT**: When creating a new spec, update the Project Structure tree in `/AGENTS.md` to include it.

## Overview

This specification defines a unified status system for OPM definitions.

**Implementation Status Note**: Currently, only `#StatusProbe` is implemented in the codebase. The `#Status` and `#Condition` definitions described in this spec are **not yet implemented** and represent the planned design. This spec documents both what exists (`#StatusProbe`) and what is planned (`#Status`, `#Condition`).

### Design Principles

1. **Unified**: A single `#Status` definition works for Component, Module, and Bundle
2. **Composable**: Status probes are reusable building blocks for health checks
3. **Native CUE**: All status logic is pure CUE, not opaque strings
4. **Interoperable**: Kubernetes-style conditions for ecosystem compatibility
5. **Flexible**: Details map allows entity-specific metrics without schema changes

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Status approach | Unified `#Status` | Simpler, consistent API across all entities |
| Scope | Static + Runtime + Counts | Complete observability without separate definitions |
| Probe naming | Keep `#StatusProbe` | Simpler name, already in use, probes are lightweight |
| Counts | Flexible via `details` map | Avoids fixed schema, entities define what they need |
| Conditions | Include Kubernetes-style | Interoperability with k8s tooling and patterns |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Define Module Health Status (Priority: P1)

As a module developer, I want to define health status for my module so that the platform controller can report whether my application is healthy at runtime.

**Why this priority**: Core functionality - without status, operators cannot know if deployments are healthy.

**Independent Test**: Can be fully tested by creating a Module with `#status` field and validating CUE evaluation produces expected static values.

**Acceptance Scenarios**:

1. **Given** a Module definition, **When** I add `#status: #Status & {valid: true, message: "Configuration valid"}`, **Then** CUE evaluation succeeds and the status fields are accessible
2. **Given** a Module with status probes defined, **When** the controller injects live state into `context.outputs`, **Then** each probe evaluates and produces a `result.healthy` boolean
3. **Given** a Module with multiple probes, **When** any probe returns `healthy: false`, **Then** the overall module health is considered unhealthy

---

### User Story 2 - Reuse Standard Status Probes (Priority: P1)

As a module developer, I want to use pre-built status probes from the catalog so that I don't have to write health check logic from scratch.

**Why this priority**: Reusability is a core value proposition - developers should leverage community probes.

**Independent Test**: Can be tested by importing a catalog probe (e.g., `#WorkloadReady`) and configuring it with `#params`.

**Acceptance Scenarios**:

1. **Given** the `#WorkloadReady` probe from catalog, **When** I configure `#params: {name: "frontend"}`, **Then** the probe is correctly parameterized to check that specific resource
2. **Given** a module using multiple catalog probes, **When** evaluated, **Then** all probes are validated and no CUE errors occur

---

### User Story 3 - Report Component Status (Priority: P2)

As a component author, I want to attach status information to my component so that it can report counts and health alongside the module.

**Why this priority**: Enables finer-grained status at the component level, complementing module-level status.

**Independent Test**: Can be tested by creating a Component with `status?: #Status` and verifying computed details.

**Acceptance Scenarios**:

1. **Given** a Component definition, **When** I add `status: #Status & {details: resourceCount: len(#resources)}`, **Then** CUE evaluation populates the resourceCount
2. **Given** a Component with status, **When** the parent Module is evaluated, **Then** component status is accessible via the module's component map

---

### User Story 4 - Add Status to Bundle (Priority: P2)

As a bundle author, I want to include status in my bundle definition so that operators can monitor the health of all modules in the bundle.

**Why this priority**: Bundles aggregate modules; their status should aggregate module health.

**Independent Test**: Can be tested by creating a Bundle with `#status?: #Status` field.

**Acceptance Scenarios**:

1. **Given** a Bundle definition, **When** I add `#status: #Status`, **Then** CUE validation passes
2. **Given** a Bundle with status probes, **When** evaluated, **Then** probes can reference state from any contained module

---

### User Story 5 - Custom Inline Probe (Priority: P3)

As a developer with unique health requirements, I want to define custom probe logic inline so that I can check application-specific conditions.

**Why this priority**: Flexibility for edge cases not covered by catalog probes.

**Independent Test**: Can be tested by defining an inline `#StatusProbe` with custom `result` logic.

**Acceptance Scenarios**:

1. **Given** a Module, **When** I define an inline probe with custom CUE logic referencing `context.outputs`, **Then** the probe compiles without error
2. **Given** a custom probe checking `context.outputs.metrics.cpuUsage < 90`, **When** controller injects metrics, **Then** the probe returns appropriate `healthy` value

---

### Edge Cases

| Case | Behavior |
|------|----------|
| Probe references missing resource | CUE evaluation error; controller reports "Unknown" status for that probe |
| Probe logic fails (e.g., div by zero) | Controller reports "Internal Error" for that probe |
| No probes defined | Runtime status defaults to "Ready" if all resources exist |
| Details map has conflicting keys | CUE unification handles conflicts (fails if incompatible values) |
| Empty conditions array | Valid; no conditions reported |

## Requirements *(mandatory)*

### Functional Requirements

#### #Condition Definition (Not Yet Implemented)

- **FR-001**: A `#Condition` definition MUST be created following the Kubernetes metav1.Condition pattern *(planned)*
- **FR-002**: `#Condition.type` MUST be a required string field (e.g., "Ready", "Available", "Progressing") *(planned)*
- **FR-003**: `#Condition.status` MUST be a required field with values: `"True"`, `"False"`, or `"Unknown"` *(planned)*
- **FR-004**: `#Condition` MAY include optional fields: `reason` (string), `message` (string), `lastTransitionTime` (ISO 8601 string), `observedGeneration` (int) *(planned)*

#### #Status Definition (Not Yet Implemented)

- **FR-005**: The `#Status` definition MUST be usable by `#Component`, `#Module`, and `#Bundle` definitions *(planned)*
- **FR-006**: `#Status` MUST support optional static field `valid` (bool) for configuration validity *(planned)*
- **FR-007**: `#Status` MUST support optional field `message` (string) for human-readable status *(planned)*
- **FR-008**: `#Status` MUST support optional field `phase` with enum values: `"healthy"`, `"degraded"`, `"pending"`, `"failed"`, `"unknown"` *(planned)*
- **FR-009**: `#Status` MUST include optional `details` map for flexible key-value diagnostics with primitive values only (bool, int, string) *(planned)*
- **FR-010**: `#Status` MUST support optional `conditions` array of `#Condition` for runtime status reporting *(planned)*
- **FR-011**: `#Status` MUST support optional `#probes` map (`#StatusProbeMap`) for runtime health checks *(planned)*
- **FR-012**: `#Status` MAY include optional timestamp fields: `lastObservedAt`, `lastUpdatedAt` (ISO 8601 format) *(planned)*

#### #StatusProbe Definition (Implemented)

- **FR-013**: `#StatusProbe` MUST include metadata with required `apiVersion` and `name` fields, and computed `fqn` *(implemented)*
- **FR-014**: `#StatusProbe` MUST define a `#params` struct for developer-provided inputs (open struct) *(implemented)*
- **FR-015**: `#StatusProbe` MUST define a `context` struct containing `outputs` (map of live resources) and `values` (deployment values) *(implemented)*
- **FR-016**: `#StatusProbe.result` MUST include required field `healthy` (bool) *(implemented)*
- **FR-017**: `#StatusProbe.result` MAY include optional fields: `message` (string), `details` (map) *(implemented - conditions not yet added)*
- **FR-018**: `#StatusProbe` MUST expose `#spec` for OpenAPI compatibility using camelCase naming pattern `(strings.ToCamel(metadata.name))` *(implemented)*

#### Controller Behavior

- **FR-019**: The platform controller MUST inject live resource state into `context.outputs` of each probe
- **FR-020**: The platform controller MUST inject deployment values into `context.values` of each probe
- **FR-021**: The platform controller MUST evaluate the `result` field of each probe after context injection
- **FR-022**: If any probe reports `healthy: false`, the entity's runtime health MUST be considered `false`
- **FR-023**: The controller MUST aggregate conditions from all probes into the entity's status conditions

#### Entity Integration (Not Yet Implemented)

- **FR-024**: `#Module` MUST use `#Status` for its `#status` field (replacing `#ModuleStatus`) *(planned - currently no #status field on #Module)*
- **FR-025**: `#Component` MUST change its `status` field to optionally use `#Status` *(planned - currently uses simple computed status)*
- **FR-026**: `#Bundle` MUST add optional `#status?: #Status` field *(planned)*
- **FR-027**: Existing modules using `#ModuleStatus` should be updated to use `#Status` *(planned)*

### Key Entities

- **#Condition**: Kubernetes-style condition following metav1.Condition pattern for interoperability. Contains type, status, and optional reason/message/timestamp.

- **#Status**: Unified status definition supporting static validation (`valid`, `message`, `phase`), runtime observability (`conditions`, `#probes`), and flexible diagnostics (`details` map). Used by Component, Module, and Bundle.

- **#StatusProbe**: Reusable health check definition with parameterized inputs (`#params`), runtime context (`context.outputs`, `context.values`), and standardized results (`result.healthy`). Evaluated by the platform controller against live system state.

- **#StatusProbeMap**: Map type for collections of status probes (`[string]: #StatusProbe`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-002**: Components, Modules, and Bundles can all use `#Status` with identical field structure
- **SC-003**: Standard catalog probes (`#WorkloadReady`, `#ConditionMet`) function correctly with the `#StatusProbe` definition
- **SC-004**: CUE validation passes for all core module files after implementation (`task cue:vet MODULE=core`)
- **SC-005**: The module-status subspec (001-core-definitions-spec/subspecs/module-status.md) references this specification
- **SC-006**: The `#Condition` definition can be reused by `#ModuleRelease` and `#BundleRelease` (replacing inline definitions)

## Assumptions

- The existing `#StatusProbe` structure is largely correct and only needs minor additions (conditions in result)
- Controllers will be updated separately to handle the new conditions aggregation
- The `details` map approach for counts provides sufficient flexibility without schema complexity
- ISO 8601 timestamp format is used consistently across OPM for all time fields

## Dependencies

- **Existing implementations**:
  - `#StatusProbe` in `catalog/v0/core/status_probe.cue`
  - Condition pattern in `catalog/v0/core/module_release.cue` (to be extracted to `#Condition`)

- **Related specifications**:
  - `001-core-definitions-spec` - Parent CUE specification
  - `010-definition-lifecycle-spec` - Lifecycle management (status is observed state, lifecycle is transitions)

## Schema Reference

### #Condition

```cue
#Condition: {
    type!:               string                        // e.g., "Ready", "Available", "Progressing"
    status!:             "True" | "False" | "Unknown"
    reason?:             string                        // Machine-readable reason (PascalCase)
    message?:            string                        // Human-readable message
    lastTransitionTime?: string                        // ISO 8601 timestamp
    observedGeneration?: int                           // Resource generation when condition was set
}
```

### #Status

```cue
#Status: {
    // Static Evaluation (Computed at CUE compile time)
    valid?:   bool                                     // Configuration validity
    message?: string                                   // Human-readable status message
    phase?:   "healthy" | "degraded" | "pending" | "failed" | "unknown"
    details?: [string]: bool | int | string            // Flexible diagnostics (counts, metrics)

    // Runtime Observability (Evaluated by Controller)
    conditions?: [...#Condition]                       // Kubernetes-style conditions
    #probes?:    #StatusProbeMap                       // Runtime health probes

    // Timestamps (Set by Controller)
    lastObservedAt?: string                            // ISO 8601
    lastUpdatedAt?:  string                            // ISO 8601
}
```

### #StatusProbe

```cue
#StatusProbe: close({
    apiVersion: "opm.dev/core/v0"
    kind:       "StatusProbe"

    metadata: {
        apiVersion!:  #NameType                        // e.g., "opm.dev/statusprobes/workload@v0"
        name!:        #NameType                        // e.g., "WorkloadReady"
        fqn:          #FQNType & "\(apiVersion)#\(name)"
        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    #params: {...}                                     // Developer-provided inputs

    context: {
        outputs: [string]: {...}                       // Live resources (injected by controller)
        values:  {...}                                 // Deployment values (injected by controller)
        metadata?: {...}                               // Optional entity metadata
    }

    result: {
        healthy!:    bool                              // Required health indicator
        message?:    string                            // Human-readable message
        details?:    [string]: bool | int | string     // Structured diagnostics
        conditions?: [...#Condition]                   // Generated conditions
    }

    #spec!: (strings.ToCamel(metadata.name)): #params  // OpenAPI compatibility
})

#StatusProbeMap: [string]: #StatusProbe
```

## Examples

### Module with Status Probes

```cue
import (
    probes "opm.dev/catalog/statusprobes/workload"
)

myModule: #Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "MyApp"
        version:    "1.0.0"
    }

    #components: {
        frontend: { /* ... */ }
        database: { /* ... */ }
    }

    #status: #Status & {
        // Static evaluation
        valid:   true
        message: "Configuration valid"
        details: {
            componentCount: len(#components)
        }

        // Runtime probes
        #probes: {
            frontendReady: probes.#WorkloadReady & {
                #params: name: "frontend"
            }
            dbSynced: probes.#ConditionMet & {
                #params: {
                    name: "database"
                    type: "Synced"
                }
            }
        }
    }
}
```

### Custom Inline Probe

```cue
myModule: #Module & {
    #status: #Status & {
        #probes: {
            cpuHealthy: core.#StatusProbe & {
                metadata: {
                    apiVersion: "example.com/probes@v0"
                    name:       "CPUHealthy"
                }
                #params: threshold: 90

                result: {
                    let usage = context.outputs.metrics.cpuUsage
                    healthy: usage < #params.threshold
                    message: "CPU usage is \(usage)%"
                }
            }
        }
    }
}
```

### Component with Status

```cue
myComponent: #Component & {
    metadata: name: "api-server"

    #resources: {
        deployment: workload.#ContainerResource & { /* ... */ }
        service:    workload.#ServiceResource & { /* ... */ }
    }

    status: #Status & {
        details: {
            resourceCount: len(#resources)
        }
    }
}
```
