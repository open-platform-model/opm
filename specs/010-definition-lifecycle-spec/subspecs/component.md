# Component Lifecycle Subsystem

**Parent Spec**: [OPM Lifecycle Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2025-12-26

## Overview

This document defines component-level lifecycle steps and transition actions. Component lifecycle describes what happens when an individual component is installed, upgraded, or deleted.

### Core Principle: Pre-Built Blocks Only

Lifecycle steps are **pre-built, reusable blocks** from a catalog - developers cannot write custom lifecycle logic. This ensures:

- **Safety** - All lifecycle operations are tested and validated
- **Consistency** - Same operations work the same way everywhere
- **Auditability** - Clear understanding of what each step does

### Lifecycle vs Other Definition Types

| Type | Purpose | When |
|------|---------|------|
| **Resource** | What exists | Always (steady state) |
| **Trait** | How it behaves | During operation |
| **Policy** | What must be true | Enforcement points |
| **Lifecycle** | What happens on transitions | Install/Upgrade/Delete |

## Schema

```cue
#ComponentLifecycle: {
    // Steps before/after initial deployment
    install?: {
        before?: [...#LifecycleStep]
        after?:  [...#LifecycleStep]
    }
    
    // Steps before/after version changes
    upgrade?: {
        before?: [...#LifecycleStep]
        after?:  [...#LifecycleStep]
    }
    
    // Steps before/after removal
    delete?: {
        before?: [...#LifecycleStep]
        after?:  [...#LifecycleStep]
    }
}

#LifecycleStep: {
    // FQN of the lifecycle block from catalog
    fqn!: string
    
    // Human-readable description (optional, for documentation)
    description?: string
    
    // Conditional execution (CUE expression evaluating to bool)
    condition?: string
    
    // Maximum execution time
    timeout?: string  // e.g., "5m", "30s"
    
    // Behavior on failure
    onFailure?: "abort" | "continue" | "rollback"
    
    // Step-specific configuration (depends on the lifecycle block)
    config?: _
}
```

## Transition Points

Component lifecycle operates at three transition points:

### Install

Triggered on initial deployment of the component.

| Phase | When | Use Case |
|-------|------|----------|
| `before` | Before resources created | Schema setup, dependency checks |
| `after` | After resources ready | Initial data seeding, health verification |

### Upgrade

Triggered when component version changes or configuration updates.

| Phase | When | Use Case |
|-------|------|----------|
| `before` | Before resources updated | Data migration, backup |
| `after` | After resources ready | Migration verification, cache warming |

### Delete

Triggered when component is removed.

| Phase | When | Use Case |
|-------|------|----------|
| `before` | Before resources deleted | Data export, graceful shutdown |
| `after` | After resources removed | Cleanup, notification |

## Execution Model

### Step Ordering

Steps within a phase execute sequentially in array order:

```cue
#lifecycle: {
    upgrade: {
        before: [
            {fqn: "opm.dev/lifecycle/data@v0#BackupDatabase"},   // 1st
            {fqn: "opm.dev/lifecycle/data@v0#RunMigrations"},    // 2nd
            {fqn: "opm.dev/lifecycle/data@v0#ValidateSchema"},   // 3rd
        ]
    }
}
```

### Failure Handling

The `onFailure` field determines behavior when a step fails:

| Value | Behavior |
|-------|----------|
| `abort` | Stop lifecycle, mark as failed (default) |
| `continue` | Log error, proceed to next step |
| `rollback` | Attempt to undo completed steps |

### Conditional Execution

Steps can be conditionally executed:

```cue
{
    fqn: "opm.dev/lifecycle/data@v0#RunMigrations"
    condition: "values.database.runMigrations == true"
    timeout: "10m"
    onFailure: "abort"
}
```

The `condition` is a CUE expression evaluated against the component context.

## Examples

### Database Component Lifecycle

```cue
database: #Component & {
    #resources: {
        "opm.dev/resources/workload@v0#Container": #Container
        "opm.dev/resources/storage@v0#Volume": #Volume
    }
    
    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opm.dev/lifecycle/data@v0#ApplySchema"
                    description: "Apply initial database schema"
                    timeout: "5m"
                    onFailure: "abort"
                    config: {
                        schemaPath: "/migrations/initial.sql"
                    }
                }
            ]
        }
        
        upgrade: {
            before: [
                {
                    fqn: "opm.dev/lifecycle/data@v0#BackupDatabase"
                    description: "Backup before migration"
                    timeout: "30m"
                    onFailure: "abort"
                    config: {
                        destination: "s3://backups/pre-upgrade"
                    }
                },
                {
                    fqn: "opm.dev/lifecycle/data@v0#RunMigrations"
                    description: "Run schema migrations"
                    condition: "values.database.autoMigrate"
                    timeout: "15m"
                    onFailure: "rollback"
                    config: {
                        migrationsPath: "/migrations"
                    }
                }
            ]
            
            after: [
                {
                    fqn: "opm.dev/lifecycle/data@v0#ValidateSchema"
                    description: "Verify schema integrity"
                    timeout: "2m"
                    onFailure: "abort"
                }
            ]
        }
        
        delete: {
            before: [
                {
                    fqn: "opm.dev/lifecycle/data@v0#ExportData"
                    description: "Export data before deletion"
                    condition: "values.database.exportOnDelete"
                    timeout: "1h"
                    onFailure: "continue"
                    config: {
                        destination: "s3://exports/final"
                    }
                }
            ]
        }
    }
    
    spec: {
        container: {
            image: "postgres:15"
        }
        volume: {
            size: "100Gi"
            storageClass: "fast-ssd"
        }
    }
}
```

### Cache Component Lifecycle

```cue
cache: #Component & {
    #resources: {
        "opm.dev/resources/workload@v0#Container": #Container
    }
    
    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opm.dev/lifecycle/cache@v0#WarmCache"
                    description: "Pre-populate cache with common queries"
                    timeout: "10m"
                    onFailure: "continue"  // Cache warming is optional
                    config: {
                        warmupScript: "/scripts/warmup.sh"
                    }
                }
            ]
        }
        
        upgrade: {
            before: [
                {
                    fqn: "opm.dev/lifecycle/cache@v0#FlushCache"
                    description: "Flush cache before upgrade"
                    timeout: "5m"
                    onFailure: "continue"
                }
            ]
            
            after: [
                {
                    fqn: "opm.dev/lifecycle/cache@v0#WarmCache"
                    description: "Re-warm cache after upgrade"
                    timeout: "10m"
                    onFailure: "continue"
                }
            ]
        }
    }
    
    spec: {
        container: {
            image: "redis:7"
        }
    }
}
```

### API Component with Health Verification

```cue
api: #Component & {
    #resources: {
        "opm.dev/resources/workload@v0#Container": #Container
    }
    
    #traits: {
        "opm.dev/traits/network@v0#Expose": #Expose
        "opm.dev/traits/observability@v0#HealthCheck": #HealthCheck
    }
    
    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opm.dev/lifecycle/health@v0#WaitForHealthy"
                    description: "Wait for API to be healthy"
                    timeout: "5m"
                    onFailure: "abort"
                    config: {
                        endpoint: "/health"
                        expectedStatus: 200
                        interval: "10s"
                    }
                },
                {
                    fqn: "opm.dev/lifecycle/test@v0#RunSmokeTests"
                    description: "Run basic smoke tests"
                    timeout: "2m"
                    onFailure: "abort"
                    config: {
                        testSuite: "smoke"
                    }
                }
            ]
        }
        
        upgrade: {
            after: [
                {
                    fqn: "opm.dev/lifecycle/health@v0#WaitForHealthy"
                    timeout: "5m"
                    onFailure: "rollback"
                },
                {
                    fqn: "opm.dev/lifecycle/test@v0#RunSmokeTests"
                    timeout: "2m"
                    onFailure: "rollback"
                }
            ]
        }
    }
    
    spec: {
        container: {
            image: "api:v2.0.0"
            ports: [{containerPort: 8080}]
        }
        expose: {
            type: "ClusterIP"
            ports: [{port: 80, targetPort: 8080}]
        }
        healthCheck: {
            path: "/health"
            port: 8080
        }
    }
}
```

## Acceptance Criteria

**Lifecycle Definition**:

1. **Given** a Component with `#lifecycle` defined, **When** evaluated, **Then** lifecycle structure validates against `#ComponentLifecycle` schema.

2. **Given** a Component without `#lifecycle`, **When** evaluated, **Then** component is valid (lifecycle is optional).

3. **Given** a `#LifecycleStep` without `fqn`, **When** evaluated, **Then** validation fails (fqn is required).

**Step Configuration**:

1. **Given** a `#LifecycleStep` with `condition` expression, **When** condition evaluates to false, **Then** step is skipped.

2. **Given** a `#LifecycleStep` with `timeout: "5m"`, **When** step exceeds 5 minutes, **Then** step fails with timeout error.

3. **Given** a `#LifecycleStep` with `onFailure: "abort"`, **When** step fails, **Then** lifecycle stops and component is marked failed.

4. **Given** a `#LifecycleStep` with `onFailure: "continue"`, **When** step fails, **Then** error is logged and next step executes.

5. **Given** a `#LifecycleStep` with `onFailure: "rollback"`, **When** step fails, **Then** previously completed steps are undone.

**Transition Points**:

1. **Given** a Component with `install.before` steps, **When** component is first deployed, **Then** steps execute before resources are created.

2. **Given** a Component with `install.after` steps, **When** component resources are ready, **Then** steps execute after resources are healthy.

3. **Given** a Component with `upgrade.before` steps, **When** component version changes, **Then** steps execute before resources are updated.

4. **Given** a Component with `delete.before` steps, **When** component is removed, **Then** steps execute before resources are deleted.

### Pre-Built Blocks**

1. **Given** a `#LifecycleStep` with valid catalog FQN, **When** executed, **Then** the catalog block runs.

2. **Given** a `#LifecycleStep` with non-existent FQN, **When** lifecycle is validated, **Then** error indicates unknown lifecycle block.

## Functional Requirements

### Lifecycle Definition

- **FR-4-001**: Component MAY define `#lifecycle: #ComponentLifecycle` for component-level transition steps.
- **FR-4-002**: Component lifecycle steps MUST reference pre-built blocks from catalog via FQN.
- **FR-4-003**: Component lifecycle executes within the context of module lifecycle (component lifecycles run first, then module lifecycle).
- **FR-4-004**: Component `install.before` runs before the component's resources are created.
- **FR-4-005**: Component `install.after` runs after the component's resources are ready.
- **FR-4-006**: Component `upgrade.before` is where data migrations typically occur.
- **FR-4-007**: Component lifecycle failures may propagate to module lifecycle based on `onFailure` setting.

## Edge Cases

| Case | Behavior |
|------|----------|
| `#lifecycle` not defined | Valid, no lifecycle steps |
| Empty `install: {}` | Valid, no install steps |
| `before` array empty | Valid, no before steps |
| Step without `timeout` | Platform default timeout applies |
| Step without `onFailure` | Defaults to `abort` |
| `condition` evaluates to error | Step fails (condition must be valid) |
| FQN not in catalog | Validation error at deploy time |
| Step config invalid for block | Validation error from block schema |
| Rollback step also fails | Rollback continues, errors logged |
| All lifecycle phases empty | Valid, component has no lifecycle hooks |

## Design Rationale

### Why Pre-Built Blocks Only?

Custom lifecycle logic introduces risks:

1. **Untested code** - Custom scripts may have bugs
2. **Security concerns** - Arbitrary code execution
3. **Inconsistency** - Different approaches to same problem
4. **Maintenance burden** - Platform team must support custom code

Pre-built blocks are:

1. **Tested** - Validated by platform team
2. **Documented** - Clear behavior and requirements
3. **Configurable** - Parameters cover common use cases
4. **Auditable** - Known operations in catalog

### Why Separate Before/After?

Clear semantics for when steps run:

- `before`: Dependencies exist, component doesn't yet
- `after`: Component exists and is ready

This enables patterns like:

- `before`: Prepare (backup, check dependencies)
- `after`: Verify (health checks, smoke tests)

### Why Sequential Execution?

Parallel execution adds complexity:

1. **Dependencies** - Steps often depend on previous steps
2. **Debugging** - Sequential is easier to trace
3. **Rollback** - Clearer undo order

Future versions may add parallel step groups if needed.

## Success Criteria

- **SC-012**: Component lifecycle steps execute in correct order (before resources, after resources).
- **SC-016**: Lifecycle steps with `onFailure: "rollback"` trigger rollback on failure.

## Future Considerations

The following are intentionally excluded and may be added later:

- **Parallel step groups**: Steps that can run concurrently
- **Step dependencies**: Explicit DAG of step dependencies
- **Custom blocks**: User-defined lifecycle blocks (with approval)
- **Step retries**: Automatic retry with backoff
- **Step metrics**: Timing and success rate tracking
- **Dry-run mode**: Preview lifecycle without executing
