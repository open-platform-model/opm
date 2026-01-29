# Module Lifecycle Subsystem

**Parent Spec**: [OPM Lifecycle Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2025-12-26

> **Moved**: This subspec has been migrated to [Module Lifecycle](../../001-core-definitions-spec/subspecs/module-lifecycle.md).

## Overview

This document defines module-level lifecycle steps and cross-component coordination. Module lifecycle describes what happens when the entire module is installed, upgraded, or deleted, after all component lifecycles have completed.

### Core Principle: Module After Components

Module lifecycle executes **after** all component lifecycles complete for the same transition phase:

```
Install Flow:
    1. All component install.before steps
    2. All component resources created
    3. All component install.after steps
    4. Module install.before steps
    5. Module install.after steps

Upgrade Flow:
    1. All component upgrade.before steps
    2. All component resources updated
    3. All component upgrade.after steps
    4. Module upgrade.before steps
    5. Module upgrade.after steps
```

This ordering ensures:

- Components are ready before module-level operations
- Module lifecycle can coordinate across components
- Rollback flows in reverse order

### Module vs Component Lifecycle

| Aspect | Component Lifecycle | Module Lifecycle |
|--------|---------------------|------------------|
| **Scope** | Single component | Entire module |
| **Timing** | Runs first | Runs after components |
| **Use case** | Component-specific (migrations) | Cross-cutting (notifications, validation) |
| **Context** | Component values | All component states |

## Schema

```cue
#ModuleLifecycle: {
    // Steps before/after initial module deployment
    install?: {
        before?: [...#LifecycleStep]
        after?:  [...#LifecycleStep]
    }
    
    // Steps before/after module version changes
    upgrade?: {
        before?: [...#LifecycleStep]
        after?:  [...#LifecycleStep]
    }
    
    // Steps before/after module removal
    delete?: {
        before?: [...#LifecycleStep]
        after?:  [...#LifecycleStep]
    }
}

// Shared with component lifecycle
#LifecycleStep: {
    fqn!:         string
    description?: string
    condition?:   string
    timeout?:     string
    onFailure?:   "abort" | "continue" | "rollback"
    config?:      _
}
```

## Execution Order

### Install

```text
┌─────────────────────────────────────────────────────────┐
│                    MODULE INSTALL                       │
├─────────────────────────────────────────────────────────┤
│  1. Component A: install.before                         │
│  2. Component B: install.before                         │
│  3. Component C: install.before                         │
├─────────────────────────────────────────────────────────┤
│  4. Component A: create resources                       │
│  5. Component B: create resources                       │
│  6. Component C: create resources                       │
├─────────────────────────────────────────────────────────┤
│  7. Component A: install.after                          │
│  8. Component B: install.after                          │
│  9. Component C: install.after                          │
├─────────────────────────────────────────────────────────┤
│  10. Module: install.before                             │
│  11. Module: install.after                              │
└─────────────────────────────────────────────────────────┘
```

### Upgrade

```text
┌─────────────────────────────────────────────────────────┐
│                    MODULE UPGRADE                       │
├─────────────────────────────────────────────────────────┤
│  1. All components: upgrade.before                      │
│  2. All components: update resources                    │
│  3. All components: upgrade.after                       │
├─────────────────────────────────────────────────────────┤
│  4. Module: upgrade.before                              │
│  5. Module: upgrade.after                               │
└─────────────────────────────────────────────────────────┘
```

### Delete

```text
┌─────────────────────────────────────────────────────────┐
│                    MODULE DELETE                        │
├─────────────────────────────────────────────────────────┤
│  1. Module: delete.before                               │
│  2. Module: delete.after (if meaningful)                │
├─────────────────────────────────────────────────────────┤
│  3. All components: delete.before                       │
│  4. All components: delete resources                    │
│  5. All components: delete.after                        │
└─────────────────────────────────────────────────────────┘
```

Note: Delete flows in reverse order - module first, then components.

## Use Cases for Module Lifecycle

Module lifecycle is for operations that:

1. **Span multiple components** - Cross-component validation
2. **Require all components ready** - Integration tests
3. **Are module-scoped** - Notifications, external registrations

### Appropriate for Module Lifecycle

| Operation | Why Module-Level |
|-----------|------------------|
| Integration tests | Need all components running |
| External notifications | One notification per module, not per component |
| Service mesh registration | Register entire module as a service |
| DNS/routing setup | Configure after all endpoints known |
| Compliance audit | Audit entire module state |

### NOT Appropriate for Module Lifecycle

| Operation | Why Component-Level |
|-----------|---------------------|
| Database migrations | Component-specific data |
| Schema setup | Single component concern |
| Cache warming | Component-specific cache |
| Health checks | Per-component health |

## Examples

### Module with Integration Testing

```cue
myModule: #Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "ECommerceApp"
        version:    "2.0.0"
    }
    
    #components: {
        api: #Component & {
            #lifecycle: {
                install: {
                    after: [
                        {fqn: "opmodel.dev/lifecycle/health@v0#WaitForHealthy"}
                    ]
                }
            }
            // ...
        }
        
        database: #Component & {
            #lifecycle: {
                install: {
                    after: [
                        {fqn: "opmodel.dev/lifecycle/data@v0#ApplySchema"}
                    ]
                }
                upgrade: {
                    before: [
                        {fqn: "opmodel.dev/lifecycle/data@v0#RunMigrations"}
                    ]
                }
            }
            // ...
        }
        
        cache: #Component & {
            // ...
        }
    }
    
    // Module-level lifecycle
    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opmodel.dev/lifecycle/test@v0#RunIntegrationTests"
                    description: "Verify all components work together"
                    timeout: "10m"
                    onFailure: "abort"
                    config: {
                        testSuite: "integration"
                        components: ["api", "database", "cache"]
                    }
                },
                {
                    fqn: "opmodel.dev/lifecycle/notify@v0#SendSlackNotification"
                    description: "Notify team of successful deployment"
                    timeout: "1m"
                    onFailure: "continue"
                    config: {
                        channel: "#deployments"
                        message: "ECommerceApp v2.0.0 deployed successfully"
                    }
                }
            ]
        }
        
        upgrade: {
            before: [
                {
                    fqn: "opmodel.dev/lifecycle/notify@v0#SendSlackNotification"
                    description: "Notify team of upgrade start"
                    timeout: "1m"
                    onFailure: "continue"
                    config: {
                        channel: "#deployments"
                        message: "Starting ECommerceApp upgrade to v2.0.0"
                    }
                }
            ]
            
            after: [
                {
                    fqn: "opmodel.dev/lifecycle/test@v0#RunIntegrationTests"
                    timeout: "10m"
                    onFailure: "rollback"
                },
                {
                    fqn: "opmodel.dev/lifecycle/test@v0#RunE2ETests"
                    description: "Full end-to-end test suite"
                    timeout: "30m"
                    onFailure: "rollback"
                    config: {
                        testSuite: "e2e"
                        parallelism: 4
                    }
                },
                {
                    fqn: "opmodel.dev/lifecycle/notify@v0#SendSlackNotification"
                    timeout: "1m"
                    onFailure: "continue"
                    config: {
                        channel: "#deployments"
                        message: "ECommerceApp upgrade to v2.0.0 complete"
                    }
                }
            ]
        }
        
        delete: {
            before: [
                {
                    fqn: "opmodel.dev/lifecycle/notify@v0#SendSlackNotification"
                    description: "Notify team of module deletion"
                    timeout: "1m"
                    onFailure: "continue"
                    config: {
                        channel: "#deployments"
                        message: "ECommerceApp being deleted"
                    }
                },
                {
                    fqn: "opmodel.dev/lifecycle/registry@v0#DeregisterService"
                    description: "Remove from service registry"
                    timeout: "2m"
                    onFailure: "continue"
                    config: {
                        serviceName: "ecommerce-app"
                    }
                }
            ]
        }
    }
}
```

### Module with External Registration

```cue
apiGatewayModule: #Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "APIGateway"
        version:    "1.0.0"
    }
    
    #components: {
        gateway: #Component & {
            #traits: {
                "opmodel.dev/traits/network@v0#Expose": #Expose
            }
            // ...
        }
    }
    
    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opmodel.dev/lifecycle/dns@v0#RegisterDNS"
                    description: "Register external DNS"
                    timeout: "5m"
                    onFailure: "abort"
                    config: {
                        domain: "api.example.com"
                        type: "A"
                        ttl: 300
                    }
                },
                {
                    fqn: "opmodel.dev/lifecycle/cert@v0#ProvisionCertificate"
                    description: "Provision TLS certificate"
                    timeout: "10m"
                    onFailure: "abort"
                    config: {
                        domain: "api.example.com"
                        issuer: "letsencrypt"
                    }
                },
                {
                    fqn: "opmodel.dev/lifecycle/mesh@v0#RegisterWithMesh"
                    description: "Register with service mesh"
                    timeout: "2m"
                    onFailure: "abort"
                    config: {
                        serviceName: "api-gateway"
                        meshNamespace: "istio-system"
                    }
                }
            ]
        }
        
        delete: {
            before: [
                {
                    fqn: "opmodel.dev/lifecycle/mesh@v0#DeregisterFromMesh"
                    timeout: "2m"
                    onFailure: "continue"
                },
                {
                    fqn: "opmodel.dev/lifecycle/dns@v0#DeregisterDNS"
                    timeout: "5m"
                    onFailure: "continue"
                    config: {
                        domain: "api.example.com"
                    }
                }
            ]
        }
    }
}
```

### Module with Compliance Validation

```cue
financialModule: #Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "PaymentProcessor"
        version:    "3.0.0"
    }
    
    #components: {
        processor: #Component & {/* ... */}
        audit:     #Component & {/* ... */}
        storage:   #Component & {/* ... */}
    }
    
    #lifecycle: {
        install: {
            after: [
                {
                    fqn: "opmodel.dev/lifecycle/compliance@v0#RunPCIDSSAudit"
                    description: "Verify PCI-DSS compliance"
                    timeout: "15m"
                    onFailure: "abort"
                    config: {
                        level: "full"
                        reportDestination: "s3://compliance-reports/"
                    }
                },
                {
                    fqn: "opmodel.dev/lifecycle/compliance@v0#RegisterAuditTrail"
                    description: "Register with audit system"
                    timeout: "2m"
                    onFailure: "abort"
                    config: {
                        auditSystem: "splunk"
                        index: "payment-audit"
                    }
                }
            ]
        }
        
        upgrade: {
            after: [
                {
                    fqn: "opmodel.dev/lifecycle/compliance@v0#RunPCIDSSAudit"
                    timeout: "15m"
                    onFailure: "rollback"
                },
                {
                    fqn: "opmodel.dev/lifecycle/compliance@v0#GenerateChangeReport"
                    description: "Generate compliance change report"
                    timeout: "5m"
                    onFailure: "continue"
                    config: {
                        compareWith: "previous-version"
                        reportDestination: "s3://compliance-reports/"
                    }
                }
            ]
        }
    }
}
```

## Acceptance Criteria

### Lifecycle Definition

1. **Given** a Module with `#lifecycle` defined, **When** evaluated, **Then** lifecycle structure validates against `#ModuleLifecycle` schema.

2. **Given** a Module without `#lifecycle`, **When** evaluated, **Then** module is valid (lifecycle is optional).

### Execution Order

1. **Given** a Module with both component and module lifecycles, **When** installed, **Then** all component lifecycles complete before module lifecycle starts.

2. **Given** a Module being deleted, **When** delete lifecycle runs, **Then** module lifecycle runs before component lifecycles.

3. **Given** a Module with `install.after` steps, **When** installed, **Then** steps run after all component resources are ready.

### Pre-Built Blocks

1. **Given** a `#LifecycleStep` with valid catalog FQN, **When** executed, **Then** the catalog block runs with provided config.

2. **Given** a `#LifecycleStep` with non-existent FQN, **When** lifecycle is validated, **Then** error indicates unknown lifecycle block.

### Failure Handling

1. **Given** a module lifecycle step with `onFailure: "abort"`, **When** step fails, **Then** entire module deployment fails.

2. **Given** a module lifecycle step with `onFailure: "rollback"`, **When** step fails, **Then** rollback of module and all components is attempted.

3. **Given** a component lifecycle failure, **When** `onFailure: "abort"`, **Then** module lifecycle does not execute.

### Context Access

1. **Given** a module lifecycle step, **When** executed, **Then** step has access to all component states and module values.

## Functional Requirements

### Lifecycle Definition

- **FR-11-001**: Module MAY define `#lifecycle: #ModuleLifecycle` for module-level transition steps.
- **FR-11-002**: Lifecycle steps MUST reference pre-built blocks from catalog via FQN.
- **FR-11-003**: Custom/inline lifecycle step implementation is NOT allowed.
- **FR-11-004**: Lifecycle transitions are: `install` (initial), `upgrade` (version change), `delete` (removal).
- **FR-11-005**: Each transition supports `before` and `after` step arrays.
- **FR-11-006**: `#LifecycleStep.condition` MAY specify a CUE expression for conditional execution.
- **FR-11-007**: Module lifecycle steps execute AFTER all component lifecycle steps complete for the same transition phase (except delete, which is reversed).

## Edge Cases

| Case | Behavior |
|------|----------|
| `#lifecycle` not defined | Valid, no module lifecycle |
| Component lifecycle fails | Module lifecycle does not run (unless `onFailure: continue`) |
| Module lifecycle fails with `rollback` | Rollback components in reverse order |
| No components have lifecycle | Module lifecycle still runs |
| Delete with `after` steps | Runs after module resources removed, before components |
| Condition references undefined value | Step fails with CUE error |
| Step timeout exceeded | Step fails, `onFailure` determines next action |
| All steps have `onFailure: continue` | Module succeeds even if all steps fail |

## Design Rationale

### Why Module Runs After Components?

Module-level operations typically need:

1. **All components ready** - Can't run integration tests with missing components
2. **Known endpoints** - DNS registration needs component addresses
3. **Complete state** - Compliance audits need full module state

### Why Delete is Reversed?

Delete needs module-level cleanup first:

1. **Deregister from external systems** - Before components disappear
2. **Export data** - While components are still accessible
3. **Notify** - Before anything is removed

Then component deletion proceeds.

### Why Pre-Built Blocks?

Same rationale as component lifecycle:

1. **Safety** - Tested operations
2. **Consistency** - Standard approach
3. **Auditability** - Known behavior

## Success Criteria

- **SC-013**: Module lifecycle executes after all component lifecycles complete.

## Future Considerations

The following are intentionally excluded and may be added later:

- **Component ordering**: Explicit order for component lifecycle execution
- **Partial upgrade**: Upgrade subset of components
- **Canary lifecycle**: Progressive rollout with lifecycle gates
- **Lifecycle hooks**: External webhook integration
- **Cross-module lifecycle**: Coordinate across multiple modules
