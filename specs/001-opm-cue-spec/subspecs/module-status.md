# Module Status Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the status system for OPM Modules. The status field serves two distinct purposes:

1. **Static Evaluation (Compile-Time)**: Providing computed summaries, validation results, and configuration insights derived purely from the module's CUE definitions.
2. **Runtime Observability (Run-Time)**: Defining composable "Probes" that the platform controller uses to observe and report the live health of the deployed application.

### Core Principle: Composable Health Probes

Status logic is built using **Probes** (`#StatusProbe`). A Probe is a reusable CUE definition that encapsulates health logic. It receives the live system state as context and outputs a standard result (healthy/unhealthy + message).

This makes status logic:

- **Reusable**: Use standard probes like `#WorkloadReady` across many modules.
- **Composable**: Build complex health checks by aggregating multiple probes.
- **Native**: Logic is defined in pure CUE, not opaque strings.

## Schema

```cue
#ModuleStatus: {
    // --------------------------------------------------------
    // Static Evaluation (Computed at CUE compile time)
    // --------------------------------------------------------

    // Static health indicator (Configuration validity)
    valid?: bool

    // Human-readable message about the configuration state
    message?: string

    // Module phase derived from health (convenience field)
    phase?: "healthy" | "degraded" | "unknown"

    // Structured diagnostic information (key-value pairs)
    // Automatically populated with basic metrics (component counts, etc.)
    details?: [string]: bool | int | string

    // --------------------------------------------------------
    // Runtime Observability (Evaluated by Controller)
    // --------------------------------------------------------

    // Map of probes to be evaluated against live state.
    // The controller injects 'context' into these definitions.
    #probes?: [Name=string]: #StatusProbe
}
```

### The `#StatusProbe` Definition

A Probe defines the contract for a health check.

```cue
#StatusProbe: {
    // Inputs provided by the developer
    #params: {...}

    // Injected by the controller at runtime
    context: {
        outputs: [string]: _  // Live resources map
        values:  {...}        // Deployment values
    }

    // Logic implemented by the probe author
    result: {
        healthy!: bool
        message?: string
        details?: {...}
    }
}
```

## Static Status (Computed at Evaluation)

During CUE evaluation (e.g., `opm build`), the static fields are populated.

**Standard Metrics (Always Included):**

- `componentCount`: Number of defined components.
- `resourceCount`: Total number of resources.
- `traitCount`: Total number of traits.
- `policyCount`: Total number of policies.

## Runtime Status (Evaluated by Controller)

At runtime, the platform controller:

1. **Collects** the live state of all resources managed by the module.
2. **Injects** this state into the `context.outputs` field of each defined Probe.
3. **Evaluates** the CUE for each Probe.
4. **Reports** the `result.healthy` and `result.message` back to the Module resource status.

## Examples

### 1. Using Standard Probes from Catalog

```cue
import (
    probes "opm.dev/catalog/statusprobes/workload"
)

myModule: #Module & {
    #components: {
        frontend: { /* ... */ }
        database: { /* ... */ }
    }

    #status: {
        #probes: {
            // Check if frontend deployment is ready
            frontendReady: probes.#WorkloadReady & {
                #params: name: "frontend"
            }
            
            // Check if database is synced
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

### 2. Defining a Custom Ad-Hoc Probe

Developers can define custom logic inline if no standard probe exists.

```cue
myModule: #Module & {
    #status: {
        #probes: {
            customCheck: core.#StatusProbe & {
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

## Functional Requirements

### Status Definition

- **FR-10-001**: Module MAY define `#status: #ModuleStatus`.
- **FR-10-002**: `#status` MUST support a `#probes` map for runtime health checks.
- **FR-10-003**: Probes MUST be instances of `#StatusProbe`.
- **FR-10-004**: The controller MUST inject live resource state into `context.outputs`.
- **FR-10-005**: The controller MUST evaluate the `result` field of each probe.
- **FR-10-006**: If any probe reports `healthy: false`, the Module's runtime health is considered `false`.
- **FR-10-007**: The system MUST automatically compute static metrics (`componentCount`, `resourceCount`) during evaluation.

## Edge Cases

| Case | Behavior |
|------|----------|
| Probe references missing resource | CUE evaluation error (handled by controller as "Unknown" status) |
| Probe logic fails (e.g. div by zero) | Controller reports "Internal Error" for that probe |
| No probes defined | Runtime status defaults to "Ready" (if all resources exist) |

## Success Criteria

- **SC-011**: Module status correctly computes health, message, and details from configuration values.
