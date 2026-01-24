# Module Values Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-21

## Overview

This document defines the configuration values system for OPM Modules. It manages the separation between the configuration **schema** (constraints) and the configuration **data** (values), and defines the precedence hierarchy for overrides.

### Core Principle: Schema vs Data

- **`#spec`**: The Schema. Defined in CUE. Sets types, constraints, and validation rules. NO default values should be here.
- **`values`**: The Data. Defined in `values.cue` and mapped to `#Module.values`. Contains the concrete default values.

### Core Principle: Immutable Platform Overrides

Values flow in a specific hierarchy. Once a higher-authority layer (Platform Team) sets a value, it can be "locked" (made concrete), preventing lower layers (End Users) from changing it.

## Schema

```cue
#Module: {
    // ...
    
    // The Schema
    // OpenAPIv3 compatible (no logic)
    #spec: _

    // The Default Values
    // Must unify with #spec
    values: _
}
```

## Value Hierarchy

1. **Module Author Defaults** (`values.cue` in module repo): The baseline defaults provided by the module author.
2. **Platform Overrides** (Platform Repository): The platform team imports the module and unifies their own `values` object. They can use concrete values (e.g., `replicas: 3`) to lock configuration.
3. **User Overrides** (Deployment Time): The end-user provides values at deploy time (e.g., `helm install -f values.yaml`). These unify with the result of 1+2.

## Examples

### 1. Module Author Definition

```cue
// module.cue
#Module & {
    #spec: {
        replicas: int & >=1
        image: string
    }
    values: {
        replicas: 1 // Default
    }
}
```

### 2. Platform Override (Locking)

```cue
// platform/prod/module.cue
import "upstream/module"

myProdModule: module.#Module & {
    values: {
        // Platform team enforces high availability
        // By making this concrete, users cannot override it easily without conflict
        replicas: 3
    }
}
```

### 3. User Attempted Override

If a user tries to deploy `myProdModule` with `replicas: 1`:

- **Result**: CUE Unification Error (`3 != 1`). The platform constraint holds.

## Functional Requirements

### Schema Definition

- **FR-7-001**: `#values` in Module MUST be an OpenAPIv3-compatible schema (no CUE templating).
- **FR-7-002**: `#spec` MUST be a pure data schema compatible with OpenAPIv3 generation (no `if/for` logic that depends on values).
- **FR-7-003**: `values.cue` file MUST contain concrete defaults satisfying the `#values` schema.
- **FR-7-004**: Value override hierarchy: developer defaults → platform team overrides → end-user overrides.
- **FR-7-005**: Platform team overrides become immutable for end-users.
- **FR-7-006**: The system relies on CUE's unification properties to enforce immutability. If a value is made concrete by an upstream actor, downstream actors cannot change it.

## Acceptance Criteria

1. **Given** a Module with `#spec.port: int` and `values.port: 80`, **When** evaluated, **Then** it is valid.
2. **Given** a Module with `#spec.port: int` and missing `values`, **When** evaluated, **Then** it is incomplete (unless intended abstract).
3. **Given** a Platform override `replicas: 3`, **When** user supplies `replicas: 2`, **Then** evaluation fails.

## Edge Cases

| Case | Behavior |
|------|----------|
| Platform-locked value override attempt | CUE unification enforces immutability - evaluation fails |
| Module missing `values.cue` | Validation fails |
| `values` does not satisfy `#spec` | CUE validation error |
| Nested value override (partial struct) | CUE unifies at field level |

## Success Criteria

- **SC-005**: Modules without `values.cue` fail validation.
- **SC-006**: Platform-locked values cannot be overridden by end-users.
