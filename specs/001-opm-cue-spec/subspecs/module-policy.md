# Module Policy Subsystem

**Parent Spec**: [OPM Core CUE Specification](../spec.md)  
**Status**: Draft  
**Last Updated**: 2025-12-26

## Overview

This document defines the OPM policy system across two application levels: scope, and module. Policies are governance constraints with enforcement consequences - they express what MUST be true, not suggestions.

| Level | Applied In | Target | Use Case |
|-------|------------|--------|----------|
| **Scope** | `#Scope.#policies` | `"scope"` | Cross-cutting constraints for component groups |
| **Module** | `#Module.#policies` | `"module"` | Runtime enforcement beyond CUE validation |

### Core Principle: Policies Have Consequences

Unlike Traits (which configure behavior), Policies enforce constraints. When a policy is violated, something happens:

| Violation Response | Description |
|--------------------|-------------|
| `block` | Reject the operation (deployment fails, request denied) |
| `warn` | Log warning but allow operation to proceed |
| `audit` | Record violation for compliance review without blocking |

### The Two Policy Levels

OPM policies operate at three distinct levels, each serving different governance needs:

## Schema

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
        target!: "scope" | "module"
        
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

## Policy Levels in Detail

### Scope-Level Policies (`target: "scope"`)

Scope policies define cross-cutting constraints that apply to multiple components. They are applied in `#Scope.#policies` and distributed to selected components.

**Use cases:**

- Network policies
- mTLS requirements
- Observability mandates

**Example:**

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

// Applied via scope
#scopes: {
    internalServices: {
        #policies: {
            "opm.dev/policies/network@v0#NetworkPolicy": #NetworkPolicy
        }
        
        appliesTo: {
            componentLabels: {
                "internal": {visibility: "internal"}
            }
        }
        
        spec: {
            networkPolicy: {
                ingress: [{from: ["api-gateway"], ports: [8080]}]
            }
        }
    }
}
```

### Module-Level Policies (`target: "module"`)

Module policies define runtime enforcement that CUE cannot validate at evaluation time. They are applied in `#Module.#policies`.

**Use cases:**

- Pod disruption budgets
- Audit logging requirements
- Rate limiting
- Runtime security policies

**Example:**

```cue
#PodDisruptionBudget: #Policy & {
    metadata: {
        apiVersion: "opm.dev/policies/reliability@v0"
        name:       "PodDisruptionBudget"
        target:     "module"
    }
    
    enforcement: {
        mode:        "runtime"
        onViolation: "block"
    }
    
    #spec: podDisruptionBudget: {
        minAvailable?:   int | string
        maxUnavailable?: int | string
    }
}

// Applied at module level
myModule: #Module & {
    #components: {...}
    
    #policies: {
        "opm.dev/policies/reliability@v0#PodDisruptionBudget": #PodDisruptionBudget
    }
    
    // Module-level policy values
    // Note: Module policies may need different application than scope
}
```

## Enforcement Configuration

### Enforcement Mode

| Mode | When Checked | Use Case |
|------|--------------|----------|
| `deployment` | At deploy time (admission controllers, pre-flight) | Schema validation, resource limits |
| `runtime` | Continuously while running | Rate limiting, quota enforcement |
| `both` | Deploy time AND runtime | Security policies |

### Violation Response

| Response | Behavior | Use Case |
|----------|----------|----------|
| `block` | Reject operation entirely | Security violations, quota breaches |
| `warn` | Log warning, allow operation | Deprecation notices, soft limits |
| `audit` | Record for review, allow operation | Compliance tracking, gradual rollout |

### Platform-Specific Enforcement

The `enforcement.platform` field allows platform-specific configuration:

```cue
enforcement: {
    mode:        "deployment"
    onViolation: "block"
    
    platform: {
        // Kyverno-specific
        kyverno: {
            validationFailureAction: "enforce"
            background: true
        }
    }
}
```

Or for OPA/Gatekeeper:

```cue
enforcement: {
    mode:        "runtime"
    onViolation: "warn"
    
    platform: {
        gatekeeper: {
            enforcementAction: "warn"
            match: {
                kinds: [{apiGroups: [""], kinds: ["Pod"]}]
            }
        }
    }
}
```

## Target Validation

CUE enforces that policies are applied at the correct level:

```cue
// In #Scope  
#policies: [PolicyFQN=string]: #Policy & {
    metadata: {
        target: "scope"  // Enforced
    }
}

// In #Module
#policies?: [PolicyFQN=string]: #Policy & {
    metadata: {
        target: "module"  // Enforced
    }
}
```

Attempting to apply a policy at the wrong level results in a CUE unification error.

## Examples

### Complete Policy Application

```cue
myModule: #Module & {
    metadata: {
        apiVersion: "example.com/modules@v0"
        name:       "SecureApp"
        version:    "1.0.0"
    }
    
    #components: {
        api: #Component & {
            #resources: {
                "opm.dev/resources/workload@v0#Container": #Container
            }
            
            spec: {
                container: {image: "api:v1"}
            }
        }
        

    }
    
    // Scope-level: cross-cutting network policy
    #scopes: {
        internalNetwork: {
            #policies: {
                "opm.dev/policies/network@v0#mTLS": #mTLSPolicy
            }
            
            appliesTo: {
                all: true
            }
            
            spec: {
                mtls: {
                    mode: "STRICT"
                }
            }
        }
    }
    
    // Module-level: runtime enforcement
    #policies: {
        "opm.dev/policies/reliability@v0#PodDisruptionBudget": #PDBPolicy
    }
}
```

## Acceptance Criteria

### Target Validation

1. **Given** a Policy with `target: "scope"`, **When** added to `#Scope.#policies`, **Then** validation succeeds.

2. **Given** a Policy with `target: "module"`, **When** added to `#Module.#policies`, **Then** validation succeeds.

### Enforcement Configuration

1. **Given** a Policy with `enforcement.mode: "deployment"`, **When** deployed, **Then** policy is checked at admission time.

2. **Given** a Policy with `enforcement.mode: "runtime"`, **When** deployed, **Then** policy is continuously monitored.

3. **Given** a Policy with `enforcement.onViolation: "block"`, **When** violated, **Then** operation is rejected.

4. **Given** a Policy with `enforcement.onViolation: "warn"`, **When** violated, **Then** warning is logged but operation proceeds.

5. **Given** a Policy with `enforcement.onViolation: "audit"`, **When** violated, **Then** violation is recorded but operation proceeds.

### Spec Integration

1. **Given** a Policy with `#spec` defining fields, **When** applied to scope, **Then** component `spec` includes policy fields.

2. **Given** multiple policies with non-conflicting specs, **When** applied to same scope, **Then** specs are merged.

3. **Given** policies with conflicting spec values, **When** applied to same scope, **Then** CUE fails with unification error.

## Functional Requirements

### Target Validation

- **FR-9-002**: Policy with `target: "scope"` can ONLY be applied to `#Scope.#policies`.
- **FR-9-003**: Policy with `target: "module"` can ONLY be applied to `#Module.#policies`.
- **FR-9-004**: `enforcement.mode: "deployment"` indicates policy is checked at deploy time.
- **FR-9-005**: `enforcement.mode: "runtime"` indicates policy is continuously enforced.
- **FR-9-006**: `enforcement.onViolation` determines consequence: `block`, `warn`, or `audit`.
- **FR-9-007**: `enforcement.platform` MAY specify platform-specific enforcement mechanism (Kyverno, OPA, etc.).

## Edge Cases

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

## Design Rationale

### Why Two Levels?

Each level serves distinct governance needs:

1. **Scope**: Cross-cutting concerns across components (network policies, mTLS)
2. **Module**: Runtime enforcement beyond CUE (PDB, audit logging)

### Why Separate Target Field?

The `target` field provides:

1. **Explicit intent** - Authors declare where the policy should be used
2. **Validation** - CUE prevents misuse at the wrong level
3. **Documentation** - Readers understand the policy's scope

### Why Enforcement Configuration?

Policies need to specify:

1. **When** they're checked (deploy vs runtime vs both)
2. **What happens** on violation (block vs warn vs audit)
3. **How** they're enforced (platform-specific)

Without this, policies are just schemas without consequences.

### Why Platform-Specific Configuration?

Different platforms have different enforcement mechanisms:

- Kubernetes: Kyverno, OPA/Gatekeeper, ValidatingWebhookConfiguration
- Cloud providers: IAM policies, Security Hub
- Service mesh: Istio AuthorizationPolicy

The `platform` field allows policies to carry platform-specific configuration without polluting the core schema.

## Future Considerations

The following are intentionally excluded and may be added later:

- **Policy inheritance**: Policies that extend other policies
- **Policy exceptions**: Explicit exemptions for specific components
- **Policy versioning**: Different policy versions for migration
- **Policy dependencies**: Policies that require other policies
- **Aggregated enforcement**: Combining multiple policy violations into single response
