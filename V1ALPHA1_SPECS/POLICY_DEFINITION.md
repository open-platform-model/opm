# Policy Definition Specification

## Overview

Policies in OPM are enforced governance rules that express security, compliance, resource management, and operational requirements. Unlike suggestions or defaults, Policies are mandatory constraints that must be satisfied for a module to be valid.

### Core Principles

- **Enforceable**: Policies are governance rules enforced by the platform, not suggestions
- **Targeted**: Each policy declares where it can be applied (Component or Scope)
- **Composable**: Policies can be defined by platform teams and module developers
- **Declarative**: Policies specify "what" must be true, not "how" to enforce it
- **Reusable**: Similar policies can be created for both contexts when needed

## Policy Validation vs Enforcement

Understanding the distinction between **validation** and **enforcement** is critical to understanding OPM policies.

### CUE Validation (Automatic)

CUE **always validates** the structure and schema of all definitions, including policies. This happens automatically when you:

- Define a ModuleDefinition
- Create a ModuleRelease with concrete values
- Run `cue vet` on your configuration

CUE validation ensures:

- Required fields are present
- Field types match the schema
- Basic constraints are satisfied (e.g., `int & >=1 & <=1000`)

**Example - Schema Constraint:**

```cue
#StatelessWorkload: {
    replicas: {
        count: int & >=1 & <=1000 | *1  // CUE validates this automatically
    }
}
```

This is a **schema constraint** - it defines what's structurally valid.

### Policy Enforcement (Platform-Specific)

**PolicyDefinitions** are different from schema constraints. They are **governance rules** that specify:

1. **What** must be enforced (the policy spec)
2. **When** enforcement happens (deployment, runtime, or both)
3. **What happens** on violation (block, warn, or audit)
4. **How** it's enforced (platform-specific mechanisms)

**Example - Policy Governance:**

```cue
#MinimumReplicasPolicy: #PolicyDefinition & {
    metadata: {
        target: "component"
        // ...
    }

    enforcement: {
        mode: "deployment"         // Enforce at deployment time
        onViolation: "block"       // Reject deployments that violate
    }

    #spec: minimumReplicas: {
        min!: int & >=3            // Production requires >=3 replicas
    }
}
```

This is a **governance rule** - it's enforced by the platform at a specific time.

### Key Differences

| Aspect | Schema Constraints | Policy Enforcement |
|--------|-------------------|-------------------|
| **What** | Define valid structure | Define required governance |
| **Where** | Part of the schema definition | Separate PolicyDefinition |
| **When** | Always (CUE evaluation) | Specified by enforcement.mode |
| **Who** | Schema authors | Platform/security teams |
| **How** | CUE type system | Platform mechanisms (Kyverno, OPA, etc.) |
| **Flexibility** | Fixed with schema | Added/removed independently |

### Why This Matters

**Separation of Concerns:**

- Schema constraints define "what's possible"
- Policies define "what's required by governance"

**Independent Governance:**

- Platform teams can add/remove policies without changing schemas
- Same schema can have different policies in different environments (dev vs prod)

**Flexible Enforcement:**

- Some policies need deployment-time checks (image signatures)
- Some need runtime monitoring (resource quotas, connectivity)
- Some need both (compliance auditing)

**Platform Integration:**

- Policies integrate with platform-native enforcement (admission controllers, policy engines)
- Enforcement is visible and auditable

## Policy Definition Structure

Every Policy follows this structure:

```cue
#PolicyDefinition: {
    // Root level: OPM core versioning
    apiVersion: "opm.dev/v1/core"  // Fixed for all v1 definitions
    kind:       "Policy"

    metadata: {
        // Element-specific versioning
        apiVersion!: string  // Element-specific version path (e.g., "opm.dev/policies/security@v1")
        name!:       string  // Policy name (e.g., "Encryption")
        fqn:         string  // Computed as "\(apiVersion)#\(name)"

        // Human-readable description
        description?: string

        // Where this policy can be applied: "component" or "scope"
        target!: "component" | "scope"

        // Classification metadata
        labels?: #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Policy enforcement configuration
    enforcement!: {
        // When enforcement happens
        mode!: "deployment" | "runtime" | "both"

        // What happens on violation
        onViolation!: "block" | "warn" | "audit"

        // Platform-specific enforcement configuration (optional)
        platform?: _
    }

    // Policy-specific constraints
    #spec: _
}
```

**Note the two-level structure:**

- **Root `apiVersion`**: Fixed `"opm.dev/v1/core"` for OPM core schema versioning
- **Metadata `apiVersion`**: Element-specific version path for the policy definition itself
- **Computed `fqn`**: Automatically derived from `metadata.apiVersion` and `metadata.name`

### Target Field

The `target` field declares where a policy can be applied:

| Target Value | Meaning | Validation |
|-------------|---------|------------|
| `"component"` | Component-level only | CUE validates this policy only appears in `#ComponentDefinition.#policies` |
| `"scope"` | Scope-level only | CUE validates this policy only appears in `#ScopeDefinition.#policies` |

### Target Constant Definition

```cue
#PolicyTarget: {
    component: "component"
    scope:     "scope"
}
```

### Enforcement Field

The `enforcement` field controls when and how the platform enforces the policy.

#### Enforcement Mode

| Mode | When | Description | Use Cases |
|------|------|-------------|-----------|
| `"deployment"` | At deployment time | Validated when resources are deployed to platform | Image signatures, admission control, pre-flight checks |
| `"runtime"` | Continuously while running | Validated during operation | Resource usage monitoring, connectivity checks, audit logging |
| `"both"` | Deployment + runtime | Validated at both times | Compliance requirements, resource quotas, security baselines |

#### On Violation Behavior

| Behavior | Effect | Description | Use Cases |
|----------|--------|-------------|-----------|
| `"block"` | Reject | Prevents deployment or operation | Production security policies, hard limits |
| `"warn"` | Log warning | Allows operation but logs violation | Soft limits, deprecation warnings |
| `"audit"` | Record only | Silently records for compliance review | Compliance tracking, post-deployment analysis |

#### Platform Configuration

The optional `platform` field allows platform-specific enforcement configuration. The structure is intentionally flexible to support different enforcement mechanisms:

**Examples:**

```cue
// Kyverno enforcement
enforcement: {
    mode: "deployment"
    onViolation: "block"
    platform: {
        engine: "kyverno"
        policyType: "ClusterPolicy"
    }
}

// OPA/Gatekeeper enforcement
enforcement: {
    mode: "both"
    onViolation: "warn"
    platform: {
        engine: "gatekeeper"
        constraintTemplate: "k8srequiredlabels"
    }
}

// Custom monitoring
enforcement: {
    mode: "runtime"
    onViolation: "audit"
    platform: {
        engine: "custom"
        checkInterval: "5m"
        alerting: {
            enabled: true
            channel: "#security-alerts"
        }
    }
}
```

## Policy Categorization

### Component-Level Policies (target: "component")

Component-level policies apply to individual components and define resource limits, security contexts, backup requirements, and component-specific governance.

**Characteristics:**

- Apply to single component's runtime behavior
- Define per-component resource allocation
- Specify component-level security and compliance
- Can vary significantly between components in the same module

**Common Use Cases:**

- Resource limits (CPU, memory, storage)
- Security contexts (user, capabilities, SELinux)
- Backup and retention requirements
- Compliance tagging and data classification
- Component-specific data residency

### Example: ResourceLimitPolicy

```cue
#ResourceLimitPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/workload@v1"
        name:        "ResourceLimit"
        fqn:         "opm.dev/policies/workload@v1#ResourceLimit"  // Computed
        description: "Enforces resource limits for component workloads"
        target:      "component"  // Component-only
    }

    enforcement: {
        mode:        "deployment"  // Enforce at deployment time
        onViolation: "block"       // Reject deployments without limits
    }

    #spec: resourceLimit: {
        cpu?: {
            request!: string & =~"^[0-9]+m$"
            limit!:   string & =~"^[0-9]+m$"
        }
        memory?: {
            request!: string & =~"^[0-9]+[MG]i$"
            limit!:   string & =~"^[0-9]+[MG]i$"
        }
    }
}

// Define wrapper that mixes policy into ComponentDefinition
#ResourceLimit: #ComponentDefinition & {
    #policies: {(#ResourceLimitPolicy.metadata.fqn): #ResourceLimitPolicy}
}
```

**Usage Pattern with Wrapper:**

```cue
// Use in component
api: #ComponentDefinition & {
    metadata: name: "api"
    #Container
    #ResourceLimit  // Mix in the wrapper

    spec: {
        container: {image: "api:latest"}
        resourceLimit: {
            cpu: {request: "100m", limit: "500m"}
            memory: {request: "128Mi", limit: "512Mi"}
        }
    }
}
```

### Scope-Level Policies (target: "scope")

Scope-level policies apply to groups of components and define cross-cutting security, network, resource quotas, and compliance requirements.

**Characteristics:**

- Apply to all components within the scope
- Define cross-cutting concerns (network, security baseline)
- Enforce organization-wide governance
- Typically set by platform teams

**Common Use Cases:**

- Network policies (traffic rules, allowed communication)
- Baseline security policies (pod security standards)
- Resource quotas (total resources for scope)
- Audit logging requirements
- Compliance frameworks (PCI, HIPAA, SOC2)

### Example: NetworkRulesPolicy

```cue
#NetworkRulesPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/connectivity@v1"
        name:        "NetworkRules"
        fqn:         "opm.dev/policies/connectivity@v1#NetworkRules"  // Computed
        description: "Defines network traffic rules"
        target:      "scope"  // Scope-only
    }

    enforcement: {
        mode:        "deployment"  // Enforce when creating network policies
        onViolation: "block"       // Reject invalid network configurations
    }

    #spec: networkRules: {
        ingress?: [...{
            from!: [...#ComponentDefinition]
            ports?: [...{
                protocol!: "TCP" | "UDP" | "SCTP"
                port!:     int & >0 & <=65535
            }]
        }]
        egress?: [...{
            to!: [...#ComponentDefinition]
            ports?: [...{
                protocol!: "TCP" | "UDP" | "SCTP"
                port!:     int & >0 & <=65535
            }]
        }]
        denyAll?: bool | *false
    }
}

// Define wrapper that mixes policy into ScopeDefinition
#NetworkRules: #ScopeDefinition & {
    #policies: {(#NetworkRulesPolicy.metadata.fqn): #NetworkRulesPolicy}
}
```

**Usage Pattern with Wrapper:**

```cue
// Use in scope
backendScope: #ScopeDefinition & {
    metadata: name: "backend"
    #NetworkRules  // Mix in the wrapper

    appliesTo: components: [api, database]

    spec: {
        networkRules: {
            allowBackend: {
                ingress: [{
                    from: [api]
                    ports: [{protocol: "TCP", port: 8080}]
                }]
                egress: [{
                    to: [database]
                    ports: [{protocol: "TCP", port: 5432}]
                }]
            }
        }
    }
}
```

### Creating Similar Policies for Both Contexts

If you need similar governance at both component and scope levels (e.g., encryption, monitoring), create **two separate policy definitions** with the same spec schema:

### Example: Encryption Policies

```cue
// Component-level encryption policy
#EncryptionPolicyComponent: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/security@v1"
        name:        "EncryptionComponent"
        fqn:         "opm.dev/policies/security@v1#EncryptionComponent"  // Computed
        description: "Enforces encryption requirements for component"
        target:      "component"
    }

    enforcement: {
        mode:        "both"     // Validate at deployment, audit at runtime
        onViolation: "block"    // Block deployments without encryption
    }

    #spec: encryption: {
        atRest?: {
            enabled!:  bool
            algorithm?: "AES-256-GCM" | "AES-128-GCM"
            keyRotation?: {
                enabled!: bool
                days?:    int & >0
            }
        }
        inTransit?: {
            enabled!:       bool
            minTLSVersion?: "1.2" | "1.3"
        }
    }
}

// Scope-level encryption policy (same spec structure)
#EncryptionPolicyScope: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/security@v1"
        name:        "EncryptionScope"
        fqn:         "opm.dev/policies/security@v1#EncryptionScope"  // Computed
        description: "Enforces encryption requirements for scope"
        target:      "scope"
    }

    enforcement: {
        mode:        "both"     // Validate at deployment, audit at runtime
        onViolation: "block"    // Block deployments without encryption
    }

    #spec: encryption: {
        atRest?: {
            enabled!:  bool
            algorithm?: "AES-256-GCM" | "AES-128-GCM"
            keyRotation?: {
                enabled!: bool
                days?:    int & >0
            }
        }
        inTransit?: {
            enabled!:       bool
            minTLSVersion?: "1.2" | "1.3"
        }
    }
}

// Create separate wrappers
#EncryptionComponent: #ComponentDefinition & {
    #policies: {(#EncryptionPolicyComponent.metadata.fqn): #EncryptionPolicyComponent}
}

#EncryptionScope: #ScopeDefinition & {
    #policies: {(#EncryptionPolicyScope.metadata.fqn): #EncryptionPolicyScope}
}
```

**Usage:**

```cue
// Apply encryption at scope level
productionScope: #ScopeDefinition & {
    metadata: name: "production"
    #EncryptionScope

    spec: {
        encryption: {
            atRest: {enabled: true}
            inTransit: {enabled: true, minTLSVersion: "1.2"}
        }
    }
}

// Apply stricter encryption at component level
database: #ComponentDefinition & {
    metadata: name: "database"
    #Container
    #EncryptionComponent

    spec: {
        container: {image: "postgres:15"}
        encryption: {
            atRest: {
                enabled: true
                algorithm: "AES-256-GCM"
                keyRotation: {enabled: true, days: 30}
            }
            inTransit: {enabled: true, minTLSVersion: "1.3"}
        }
    }
}
```

## CUE Validation Rules

### ComponentDefinition Validation

```cue
#ComponentDefinition: {
    #units: {...}
    #traits: {...}
    #blueprints?: {...}

    // Policies in components must have target: "component"
    #policies?: [PolicyFQN=string]: #PolicyDefinition & {
        metadata: {
            target: "component"
        }
    }
}
```

**Validation Logic:**

- `target: "component"` ✅ Valid
- `target: "scope"` ❌ Invalid (CUE error: scope-only policy cannot be applied to component)

### ScopeDefinition Validation

```cue
#ScopeDefinition: {
    // Policies in scopes must have target: "scope"
    #policies: [PolicyFQN=string]: #PolicyDefinition & {
        metadata: {
            target: "scope"
        }
    }
    appliesTo: {...}
}
```

**Validation Logic:**

- `target: "scope"` ✅ Valid
- `target: "component"` ❌ Invalid (CUE error: component-only policy cannot be applied to scope)

### Validation Error Examples

**Attempting to use scope-only policy in component:**

```cue
api: #ComponentDefinition & {
    #policies: {
        "opm.dev/policies/connectivity@v1#NetworkRules": #NetworkRulesPolicy  // target: "scope"
    }
}
```

**CUE Error:**

```cue
api.#policies."opm.dev/policies/connectivity@v1#NetworkRules".metadata.target:
  conflicting values "scope" and "component"
```

**Attempting to use component-only policy in scope:**

```cue
backendScope: #ScopeDefinition & {
    #policies: {
        "opm.dev/policies/workload@v1#ResourceLimit": #ResourceLimitPolicy  // target: "component"
    }
}
```

**CUE Error:**

```cue
backendScope.#policies."opm.dev/policies/workload@v1#ResourceLimit".metadata.target:
  conflicting values "component" and "scope"
```

## Standard Policy Types

### 1. ResourceLimitPolicy (Component-Level)

```cue
#ResourceLimitPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/workload@v1"
        name:        "ResourceLimit"
        fqn:         "opm.dev/policies/workload@v1#ResourceLimit"  // Computed
        description: "Enforces resource limits for component workloads"
        target:      "component"
        labels: {
            category: "resource-management"
            severity: "high"
        }
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }

    #spec: resourceLimit: {
        cpu?: {
            request!: string & =~"^[0-9]+m$"
            limit!:   string & =~"^[0-9]+m$"
        }
        memory?: {
            request!: string & =~"^[0-9]+[MG]i$"
            limit!:   string & =~"^[0-9]+[MG]i$"
        }
        storage?: {
            request!: string & =~"^[0-9]+[GT]i$"
        }
    }
}
```

### 2. SecurityContextPolicy (Component-Level)

```cue
#SecurityContextPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/security@v1"
        name:        "SecurityContext"
        fqn:         "opm.dev/policies/security@v1#SecurityContext"  // Computed
        description: "Enforces container security context requirements"
        target:      "component"
        labels: {
            category: "security"
            severity: "critical"
        }
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }

    #spec: securityContext: {
        runAsNonRoot!: bool
        runAsUser?:    int & >=1000
        readOnlyRootFilesystem?:   bool
        allowPrivilegeEscalation?: bool | *false
        capabilities?: {
            drop?: [...string]
            add?:  [...string]
        }
    }
}
```

### 3. NetworkRulesPolicy (Scope-Level)

```cue
#NetworkRulesPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/connectivity@v1"
        name:        "NetworkRules"
        fqn:         "opm.dev/policies/connectivity@v1#NetworkRules"  // Computed
        description: "Defines allowed network traffic between components"
        target:      "scope"
        labels: {
            category: "networking"
            severity: "high"
        }
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }

    #spec: networkRules: {
        ingress?: [...{
            from!: [...#ComponentDefinition]
            ports?: [...{
                protocol!: "TCP" | "UDP" | "SCTP"
                port!:     int & >0 & <=65535
            }]
        }]
        egress?: [...{
            to!: [...#ComponentDefinition]
            ports?: [...{
                protocol!: "TCP" | "UDP" | "SCTP"
                port!:     int & >0 & <=65535
            }]
        }]
        denyAll?: bool | *false
    }
}
```

### 4. PodSecurityPolicy (Scope-Level)

```cue
#PodSecurityPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/security@v1"
        name:        "PodSecurity"
        fqn:         "opm.dev/policies/security@v1#PodSecurity"  // Computed
        description: "Enforces pod security standards baseline"
        target:      "scope"
        labels: {
            category: "security"
            severity: "critical"
            standard: "pod-security-standard"
        }
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }

    #spec: podSecurity: {
        level!:       "privileged" | "baseline" | "restricted"
        enforcement!: "enforce" | "audit" | "warn"
        version?:     string | *"latest"
    }
}
```

### 5. BackupRetentionPolicy (Component-Level)

```cue
#BackupRetentionPolicy: #PolicyDefinition & {
    apiVersion: "opm.dev/v1/core"
    kind:       "Policy"

    metadata: {
        apiVersion:  "opm.dev/policies/data@v1"
        name:        "BackupRetention"
        fqn:         "opm.dev/policies/data@v1#BackupRetention"  // Computed
        description: "Enforces backup and retention requirements for stateful components"
        target:      "component"
        labels: {
            category: "data-management"
            severity: "high"
        }
    }

    enforcement: {
        mode:        "both"    // Validate config at deployment, monitor execution at runtime
        onViolation: "warn"    // Warn on missing backups (don't block deployment)
    }

    #spec: backupRetention: {
        enabled!: bool
        schedule!: string  // Cron format
        retention?: {
            daily?:   int & >0
            weekly?:  int & >0
            monthly?: int & >0
        }
        destination!: {
            type!:       "s3" | "gcs" | "azure-blob"
            location!:   string
            encryption?: bool
        }
    }
}
```

## Complete Example

### Multi-Tier Application with Mixed Policies

```cue
package example

import opm "github.com/open-platform-model/core@v1"

#ModuleDefinition: opm.#ModuleDefinition & {
    #apiVersion: "v1"

    #components: {
        // Frontend component with resource limits
        frontend: #ComponentDefinition & {
            metadata: name: "frontend"
            #Container
            #ResourceLimit

            spec: {
                container: {
                    image: "frontend:latest"
                    ports: http: {
                        containerPort: 3000
                        protocol:      "TCP"
                    }
                }
                resourceLimit: {
                    cpu: {request: "50m", limit: "200m"}
                    memory: {request: "64Mi", limit: "256Mi"}
                }
            }
        }

        // Backend API with resource limits and security context
        api: #ComponentDefinition & {
            metadata: name: "api"
            #Container
            #ResourceLimit
            #SecurityContext

            spec: {
                container: {
                    image: "api:latest"
                    ports: http: {
                        containerPort: 8080
                        protocol:      "TCP"
                    }
                }
                resourceLimit: {
                    cpu: {request: "100m", limit: "500m"}
                    memory: {request: "128Mi", limit: "512Mi"}
                }
                securityContext: {
                    runAsNonRoot:              true
                    runAsUser:                 1000
                    readOnlyRootFilesystem:    true
                    allowPrivilegeEscalation:  false
                }
            }
        }

        // Database with resource limits and backup policy
        database: #ComponentDefinition & {
            metadata: name: "database"
            #Container
            #ResourceLimit
            #BackupRetention

            spec: {
                container: {
                    image: "postgres:15"
                    ports: db: {
                        containerPort: 5432
                        protocol:      "TCP"
                    }
                }
                resourceLimit: {
                    cpu: {request: "500m", limit: "2000m"}
                    memory: {request: "1Gi", limit: "4Gi"}
                }
                backupRetention: {
                    enabled: true
                    schedule: "0 2 * * *"  // Daily at 2am
                    retention: {
                        daily:   7
                        weekly:  4
                        monthly: 12
                    }
                    destination: {
                        type:       "s3"
                        location:   "s3://backups/database"
                        encryption: true
                    }
                }
            }
        }
    }

    #scopes: {
        // Production scope with network and security policies
        "production": #ScopeDefinition & {
            metadata: name: "production"
            #NetworkRules
            #PodSecurity

            appliesTo: components: [frontend, api, database]

            spec: {
                networkRules: {
                    allowFrontend: {
                        ingress: [{
                            from: [frontend]
                            ports: [{protocol: "TCP", port: 3000}]
                        }]
                    }
                    allowBackend: {
                        ingress: [{
                            from: [api]
                            ports: [{protocol: "TCP", port: 8080}]
                        }]
                        egress: [{
                            to: [database]
                            ports: [{protocol: "TCP", port: 5432}]
                        }]
                    }
                }
                podSecurity: {
                    level:       "baseline"
                    enforcement: "enforce"
                }
            }
        }
    }
}
```

## Best Practices

### 1. Choose the Right Target

**Use Component-Level Policies When:**

- Requirements vary significantly between components
- Policy applies to single component's runtime behavior
- Resource allocation needs are component-specific
- Component has unique security or compliance needs

**Use Scope-Level Policies When:**

- Requirements apply uniformly across multiple components
- Policy defines cross-cutting concerns (network, security baseline)
- Organization-wide governance must be enforced
- Reducing duplication across similar components

### 2. Creating Similar Policies for Both Contexts

When you need similar governance at both levels:

1. Create two separate policy definitions with same spec schema
2. Suffix names to distinguish context: `EncryptionComponent`, `EncryptionScope`
3. Create separate wrapper definitions for each
4. Use independently in components and scopes

**Don't:**

- Try to share a single policy definition between component and scope
- Use the same FQN for both policy types

### 3. Policy Naming Conventions

Use fully qualified names (FQNs) following this format:

```
<repo-path>@v<major>#<PolicyName>
```

Examples:

- `opm.dev/policies/workload@v1#ResourceLimit`
- `opm.dev/policies/security@v1#EncryptionComponent`
- `opm.dev/policies/security@v1#EncryptionScope`
- `myorg.com/policies/compliance@v1#SOC2Compliance`

### 4. Policy Granularity

**Do:**

- Create focused policies with single responsibility
- Compose multiple policies rather than creating monolithic ones
- Use wrapper definitions for ergonomic policy application

**Don't:**

- Combine unrelated concerns in single policy
- Create overly specific policies for one-off requirements
- Duplicate policy logic across multiple policy types

### 5. Wrapper Pattern

The wrapper pattern provides ergonomic policy application:

```cue
// Define policy
#MyPolicy: #PolicyDefinition & {
    target: "component"
    #spec: myPolicy: {...}
}

// Create wrapper that mixes policy into ComponentDefinition
#MyPolicyWrapper: #ComponentDefinition & {
    #policies: {(#MyPolicy.metadata.fqn): #MyPolicy}
}

// Use wrapper in components
myComponent: #ComponentDefinition & {
    #Container
    #MyPolicyWrapper  // Mix in via wrapper

    spec: {
        container: {...}
        myPolicy: {...}  // Configure policy
    }
}
```

### 6. Validation and Testing

**During Development:**

- Use `cue vet` to validate policy constraints
- Test policy application at both component and scope levels
- Verify CUE catches invalid policy placements

**Before Deployment:**

- Validate all policies have required target fields
- Ensure scope policies don't conflict with component policies
- Test wrapper definitions work correctly

**Example Validation:**

```bash
# Validate module definition
cue vet module.cue

# Export to verify final unified result
cue export module.cue
```

### 7. Documentation

**For Each Policy:**

- Clearly document what constraints are enforced
- Provide examples for usage with wrapper pattern
- Document any platform-specific behavior
- Include migration guidance when updating policies

**In Module Definitions:**

- Comment why specific policies are applied
- Link to compliance requirements or security standards

### 8. Versioning

- Use semantic versioning for policy definitions
- Breaking changes require major version bump
- Add new optional fields for backward compatibility
- Deprecate old fields before removing them

## Migration Guide

### Migrating from Untyped Policies

If your current OPM implementation has policies without target fields:

#### Step 1: Add target field to all policy definitions

Before:

```cue
#ResourceLimitPolicy: #PolicyDefinition & {
    metadata: {
        name: "ResourceLimit"
        description: "..."
    }
    #spec: {...}
}
```

After:

```cue
#ResourceLimitPolicy: #PolicyDefinition & {
    metadata: {
        name:        "ResourceLimit"
        description: "..."
        target:      "component"  // Add target
    }
    #spec: {...}
}
```

#### Step 2: Update component and scope definitions

Add validation to component and scope schemas (see [CUE Validation Rules](#cue-validation-rules))

#### Step 3: Update existing module definitions

- Review all policy usages
- Move misplaced policies to correct location
- Add component-level policies where needed

#### Step 4: Validate

```bash
cue vet ./...  # Will catch any invalid policy placements
```

### Migrating from Scope-Only Policies

If policies were previously only applicable at scope level:

#### Step 1: Identify candidates for component-level

- Resource limits → Component-level
- Security contexts → Component-level
- Backup requirements → Component-level

#### Step 2: Create component-level versions

For each policy that needs component-level variant:

1. Create new policy definition with `target: "component"`
2. Reuse same spec schema
3. Create wrapper definition
4. Suffix name to distinguish: `PolicyNameComponent`

#### Step 3: Refactor module definitions

- Add component-specific policies to components
- Keep cross-cutting policies in scopes
- Update wrapper usages

## Future Considerations

### Planned Enhancements

1. **Policy Templates**: Reusable policy patterns with parameters
2. **Policy Inheritance**: Scope hierarchies with policy inheritance
3. **Conditional Policies**: Policies activated based on runtime conditions
4. **Policy Reporting**: Tooling to generate policy compliance reports
5. **Policy Testing Framework**: Automated testing for policy validation

### Extensibility

Organizations can define custom policies following the same structure:

```cue
package mypolicies

import opm "github.com/open-platform-model/core@v1"

#CustomCompliancePolicy: opm.#PolicyDefinition & {
    metadata: {
        name:        "CustomCompliance"
        description: "Organization-specific compliance requirements"
        target:      "scope"
        labels: {
            category:     "compliance"
            organization: "myorg"
        }
    }

    enforcement: {
        mode:        "both"    // Validate at deployment, audit at runtime
        onViolation: "audit"   // Record violations for compliance review
    }

    #spec: {
        // Custom policy constraints
        ...
    }
}
```

## References

- [DEFINITION_TYPES.md](DEFINITION_TYPES.md) - Core definition type specifications
- [core/v1/policy.cue](../../core/v1/policy.cue) - Policy schema implementation
- [core/v1/component.cue](../../core/v1/component.cue) - Component definition with policies
- [core/v1/scope.cue](../../core/v1/scope.cue) - Scope definition with policies
- [docs/architecture.md](../docs/architecture.md) - OPM architecture overview
