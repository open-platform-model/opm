# Values Overlay System

**Parent Spec**: [015-platform-runtime-spec](../spec.md)  
**Status**: Draft  
**Last Updated**: 2026-01-28

## Overview

The values overlay system defines how configuration values flow through OPM's tiered authority model, from Module Author defaults through Platform Operator customizations to End User deployments.

## Design Principles

### 1. Clear Authority Hierarchy

Values flow through three tiers with increasing authority:

```
Module Author → Platform Operator → End User
   (Tier 1)         (Tier 2)        (Tier 3)
```

Higher tiers can override lower tiers, but the override rules depend on how values are specified.

### 2. Explicit Locking via Concrete Values

Platform Operators control which values End Users can override:
- **Concrete values** (e.g., `replicas: 3`) are **locked** - End Users cannot override
- **Default values** (e.g., `replicas: *3 | int`) are **overridable** - End Users can provide alternatives

### 3. Deep Merge Semantics

Values merge deeply (field-by-field) rather than replacing entire structures. This allows granular overrides while preserving unspecified fields.

## Tier Model

### Tier 1: Module Author

**Location**: Module's `values.cue` file in module repository

**Authority**: Lowest - provides baseline defaults

**Rules**:
- MUST provide concrete default values for all config fields
- CANNOT use `*` (default markers) on values
- Values MUST satisfy the module's `config` schema
- Purpose: sane defaults that work out-of-the-box

**Example**:
```cue
// module-repo/values.cue
values: {
    image:    "nginx:latest"
    port:     8080
    replicas: 1
    resources: {
        requests: { cpu: "100m", memory: "128Mi" }
    }
}
```

---

### Tier 2: Platform Operator

**Location**: Platform repository overlay files or catalog overlays

**Authority**: Medium - enforces platform standards

**Rules**:
- MAY use concrete values to lock configuration (End User cannot override)
- MAY use `*` default markers to allow End User overrides
- MAY add new values for extended config fields
- Values MUST satisfy the module's `config` schema (including extensions)
- Purpose: platform governance and defaults

**Example**:
```cue
// platform-repo/overlays/webapp-prod.cue
values: {
    replicas: 3                    // LOCKED: concrete value
    image: *"nginx:1.25.0" | _     // DEFAULT: can override with image: "nginx:1.26.0"
    resources: {
        limits: {
            cpu:    "2000m"        // LOCKED: concrete value
            memory: "2Gi"          // LOCKED: concrete value
        }
    }
    environment: "production"      // NEW: added by platform
}
```

---

### Tier 3: End User

**Location**: `#ModuleRelease.values` or CLI-provided values file

**Authority**: Highest for unlocked values - provides deployment-specific configuration

**Rules**:
- CAN override values with `*` (default markers) from Tier 2
- CANNOT override locked (concrete) values from Tier 2
- Values MUST satisfy the module's `config` schema
- Purpose: deployment-specific customization

**Example**:
```cue
// release-values.cue
values: {
    image: "nginx:1.26.0"  // ✅ Allowed: Tier 2 used *
    replicas: 5            // ❌ ERROR: Tier 2 locked with concrete 3
    
    // Can set fields not locked by platform
    ingress: {
        host: "myapp.example.com"
    }
}
```

## Merge Algorithm

### Deep Merge Rules

Inspired by Timoni's merge algorithm with OPM-specific locking:

| Type | Merge Behavior |
|------|----------------|
| **Structs** | Recursive field-by-field merge. Overlay adds/overrides fields, base preserves unspecified fields. |
| **Lists** | Overlay completely replaces base (no element-wise merge). |
| **Scalars** | Overlay replaces base, UNLESS base is concrete and overlay conflicts (then error). |

### Merge Order

```
1. Start with Module Author values (Tier 1)
2. Apply Platform Operator overlays in order (Tier 2)
3. Apply End User values (Tier 3)
```

### Conflict Resolution

| Scenario | Behavior |
|----------|----------|
| Tier 2 concrete + Tier 3 different | **ERROR**: Clear message about locked value |
| Tier 2 `*` default + Tier 3 value | **ALLOWED**: Tier 3 overrides |
| Tier 1 value + Tier 2 concrete | **ALLOWED**: Tier 2 overrides |
| Multiple Tier 2 overlays | Later overlay wins |

## Examples

### Example 1: Successful Override (Default Marker)

**Tier 1 (Module Author)**:
```cue
values: {
    image: "nginx:latest"
    replicas: 1
}
```

**Tier 2 (Platform Operator)**:
```cue
values: {
    image: *"nginx:1.25.0" | _  // Default: allows override
    replicas: 3                  // Locked: concrete
}
```

**Tier 3 (End User)**:
```cue
values: {
    image: "nginx:1.26.0"  // ✅ SUCCESS: overrides default
}
```

**Effective Values**:
```cue
values: {
    image: "nginx:1.26.0"     // From Tier 3
    replicas: 3                // From Tier 2 (locked)
}
```

---

### Example 2: Locked Value Error

**Tier 2 (Platform Operator)**:
```cue
values: {
    replicas: 3  // Locked: concrete
}
```

**Tier 3 (End User)**:
```cue
values: {
    replicas: 5  // ❌ Attempts to override locked value
}
```

**Result**: ERROR with message:
```
Error: Cannot override locked value

  Field:    replicas
  Locked:   3 (set by Platform Operator)
  Provided: 5 (End User)

  The Platform Operator has set this value as concrete and it cannot be
  overridden. Contact your platform team if you need a different value.

  Locked in: platform-repo/overlays/webapp-prod.cue:3
```

---

### Example 3: Deep Merge

**Tier 1**:
```cue
values: {
    resources: {
        requests: { cpu: "100m", memory: "128Mi" }
        limits: { memory: "256Mi" }
    }
}
```

**Tier 2**:
```cue
values: {
    resources: {
        limits: { cpu: "1000m", memory: "1Gi" }
    }
}
```

**Effective Values** (deep merge):
```cue
values: {
    resources: {
        requests: { cpu: "100m", memory: "128Mi" }  // From Tier 1
        limits: { cpu: "1000m", memory: "1Gi" }     // From Tier 2
    }
}
```

---

### Example 4: List Replacement

**Tier 1**:
```cue
values: {
    tolerations: [
        {key: "node-role", operator: "Equal", value: "worker"},
    ]
}
```

**Tier 2**:
```cue
values: {
    tolerations: [
        {key: "node-role", operator: "Equal", value: "infra"},
        {key: "env", operator: "Equal", value: "prod"},
    ]
}
```

**Effective Values** (list replaced):
```cue
values: {
    tolerations: [
        {key: "node-role", operator: "Equal", value: "infra"},
        {key: "env", operator: "Equal", value: "prod"},
    ]
}
```

## Multi-format Support

### Supported Formats

| Format | Extension | Conversion |
|--------|-----------|------------|
| CUE | `.cue` | Native |
| YAML | `.yaml`, `.yml` | Convert to CUE via `encoding/yaml` |
| JSON | `.json` | Convert to CUE via `encoding/json` |

### Conversion Process

```
1. Detect format by file extension
2. Parse file content
3. Convert to CUE value
4. Extract at well-known path (e.g., "values")
5. Merge with previous layers
```

### Example: YAML Values

**platform-values.yaml**:
```yaml
values:
  replicas: 3
  image: nginx:1.25.0
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
```

CLI converts to CUE:
```cue
values: {
    replicas: 3
    image: "nginx:1.25.0"
    resources: limits: {
        cpu:    "2000m"
        memory: "2Gi"
    }
}
```

## Functional Requirements

- **FR-VO-001**: Values MUST flow through three tiers: Module Author → Platform Operator → End User
- **FR-VO-002**: Module Author values MUST be concrete (no `*` markers)
- **FR-VO-003**: Platform Operator MAY use `*` to create overridable defaults
- **FR-VO-004**: Platform Operator concrete values MUST be immutable to End Users
- **FR-VO-005**: Values MUST merge deeply (field-by-field for structs)
- **FR-VO-006**: Lists MUST be replaced entirely (no element merge)
- **FR-VO-007**: Conflicts with locked values MUST produce clear error messages
- **FR-VO-008**: Error messages MUST indicate the locked value, source tier, and file location
- **FR-VO-009**: CLI MUST support CUE, YAML, and JSON value files
- **FR-VO-010**: Multi-format files MUST be converted to CUE before merging
- **FR-VO-011**: All values MUST satisfy the module's `config` schema at each tier

## CLI Integration

### Commands

```bash
# Merge and show effective values
opm values merge module.cue \
  --overlay platform-values.cue \
  --overlay user-values.yaml

# Validate values against schema
opm values validate module.cue user-values.yaml

# Show values provenance (which tier set what)
opm values inspect module.cue \
  --overlay platform-values.cue \
  --overlay user-values.yaml

# Diff values between tiers
opm values diff \
  --base module.cue \
  --overlay platform-values.cue

# Check if user values conflict with locks
opm values check module.cue \
  --platform platform-values.cue \
  --user user-values.yaml
```

### CLI Output Examples

**Provenance inspection**:
```
Values Provenance for webapp:

  replicas: 3
    Source: Platform Operator (Tier 2)
    File:   platform-repo/overlays/webapp-prod.cue:3
    Status: LOCKED (concrete value)

  image: "nginx:1.26.0"
    Source: End User (Tier 3)
    File:   user-values.yaml:2
    Status: Overridden platform default (*"nginx:1.25.0")

  resources.requests.cpu: "100m"
    Source: Module Author (Tier 1)
    File:   module-repo/values.cue:7
    Status: Default (not overridden)
```

## Acceptance Criteria

1. **Given** Module Author provides `values.cue` with defaults
2. **When** Platform Operator adds overlay with concrete value
3. **Then** End User cannot override that value

4. **Given** Platform Operator uses `*` default marker
5. **When** End User provides different value
6. **Then** End User value is accepted

7. **Given** End User attempts to override locked value
8. **When** validation runs
9. **Then** clear error message shows locked value and source

10. **Given** values in YAML format
11. **When** CLI processes them
12. **Then** they are converted to CUE and merged correctly

## Edge Cases

| Case | Behavior |
|------|----------|
| Module Author uses `*` on values | Validation error (not allowed) |
| Platform uses `*` with multiple alternatives | Only default value is effective |
| End User provides invalid value type | Schema validation fails |
| Overlays in different formats | All converted to CUE, then merged |
| Circular value references | CUE evaluation error |
| Missing required config field | Schema validation fails |

## Success Criteria

- **SC-VO-001**: Error messages clearly identify locked values and their source
- **SC-VO-002**: Platform Operators successfully lock values in 100% of attempts
- **SC-VO-003**: End Users understand which values they can override from error messages
- **SC-VO-004**: Multi-format support enables 90% of Helm users to migrate without rewriting YAML
